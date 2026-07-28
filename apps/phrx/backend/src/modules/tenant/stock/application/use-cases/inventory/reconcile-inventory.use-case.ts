import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  getLoteQuantidadeFromMovements,
  syncLoteStockBalanceCache,
} from "../../../domain/lote-stock.service";
import { syncStockBalanceCache } from "../../../domain/produto-stock.service";
import { inventarioItemInclude, mapInventarioDetalhe } from "./inventory.mapper";

export class ReconcileInventoryUseCase {
  async execute(inventarioId: string, userId: string) {
    const prisma = getPrisma();

    return prisma.$transaction(async (tx: any) => {
      const id = BigInt(inventarioId);
      await tx.$executeRaw`SELECT id FROM inventarios WHERE id = ${id} FOR UPDATE`;

      const inventario = await tx.inventario.findUnique({
        where: { id },
        include: { itens: true },
      });

      if (!inventario) {
        throw new Error("Inventário não encontrado");
      }

      if (inventario.status !== "EM_CONTAGEM") {
        throw new Error("Apenas inventários em contagem podem ser concluídos");
      }

      const itensComDivergencia = inventario.itens.filter(
        (item: { divergencia: unknown; loteId: bigint | null }) =>
          Number(item.divergencia) !== 0 && item.loteId != null,
      );

      const produtoIds = [
        ...new Set(
          itensComDivergencia.map((item: { produtoId: bigint }) =>
            item.produtoId.toString(),
          ),
        ),
      ].map((pid) => BigInt(pid));

      for (const produtoId of produtoIds) {
        await tx.$executeRaw`SELECT id FROM produtos WHERE id = ${produtoId} FOR UPDATE`;
      }

      for (const item of itensComDivergencia) {
        const loteId = item.loteId as bigint;
        await tx.$executeRaw`SELECT id FROM lotes WHERE id = ${loteId} FOR UPDATE`;

        const estoqueAnterior = await getLoteQuantidadeFromMovements(tx, loteId);
        const estoqueFinal = Math.max(0, Number(item.estoqueContado));
        const delta = estoqueFinal - estoqueAnterior;

        if (delta === 0) {
          continue;
        }

        await tx.estoqueMovimento.create({
          data: {
            produtoId: item.produtoId,
            loteId,
            userId: BigInt(userId),
            tipo: "AJUSTE",
            quantidade: Math.abs(delta),
            estoqueAnterior,
            estoqueFinal,
            origem: "RECONCILIACAO_INVENTARIO",
            observacoes: `Conclusão Inventário ${inventario.codigo}`,
          },
        });

        await syncLoteStockBalanceCache(tx, { id: loteId });
      }

      for (const produtoId of produtoIds) {
        await syncStockBalanceCache(tx, produtoId);
        await tx.produto.update({
          where: { id: produtoId },
          data: { version: { increment: 1 } },
        });
      }

      const updated = await tx.inventario.update({
        where: { id },
        data: {
          status: "RECONCILIADO",
          reconciliadoPorId: BigInt(userId),
          reconciliadoEm: new Date(),
        },
        include: {
          iniciadoPor: { select: { id: true, name: true } },
          reconciliadoPor: { select: { id: true, name: true } },
          itens: {
            include: inventarioItemInclude,
            orderBy: [{ produtoId: "asc" }, { loteId: "asc" }],
          },
        },
      });

      return mapInventarioDetalhe(updated);
    });
  }
}

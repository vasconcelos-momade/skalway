import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import type { AddInventoryItemDTO } from "../../dto/inventory.dto";
import { getLoteQuantidadeFromMovements } from "../../../domain/lote-stock.service";
import { inventarioItemInclude, mapInventarioItem } from "./inventory.mapper";

export class AddInventoryItemUseCase {
  async execute(inventarioId: string, data: AddInventoryItemDTO) {
    const prisma = getPrisma();

    return prisma.$transaction(async (tx: any) => {
      const invId = BigInt(inventarioId);
      const produtoId = BigInt(data.produtoId);
      const loteId = BigInt(data.loteId);

      await tx.$executeRaw`SELECT id FROM inventarios WHERE id = ${invId} FOR UPDATE`;

      const inventario = await tx.inventario.findUnique({ where: { id: invId } });
      if (!inventario) {
        throw new Error("Inventário não encontrado");
      }

      if (inventario.status !== "EM_CONTAGEM" && inventario.status !== "ABERTO") {
        throw new Error(
          "Só é possível inventariar com inventário aberto ou em contagem",
        );
      }

      if (inventario.status === "ABERTO") {
        await tx.inventario.update({
          where: { id: invId },
          data: { status: "EM_CONTAGEM" },
        });
      }

      const lote = await tx.lote.findFirst({
        where: {
          id: loteId,
          produtoId,
          deletedAt: null,
          ativo: true,
        },
        include: {
          stockBalance: { select: { quantidadeTotal: true } },
          produto: { select: { id: true, ativo: true, deletedAt: true } },
        },
      });

      if (!lote || !lote.produto || lote.produto.deletedAt || !lote.produto.ativo) {
        throw new Error("Lote inválido ou produto inapto para inventário");
      }

      const existing = await tx.inventarioItem.findFirst({
        where: { inventarioId: invId, produtoId, loteId },
      });

      if (existing) {
        throw new Error("Este lote já foi inventariado neste inventário");
      }

      const estoqueSistema = await getLoteQuantidadeFromMovements(tx, loteId);
      const estoqueContado = data.estoqueContado;
      const divergencia = estoqueContado - estoqueSistema;

      const created = await tx.inventarioItem.create({
        data: {
          inventarioId: invId,
          produtoId,
          loteId,
          estoqueSistema,
          estoqueContado,
          divergencia,
        },
        include: inventarioItemInclude,
      });

      return mapInventarioItem(created);
    });
  }
}

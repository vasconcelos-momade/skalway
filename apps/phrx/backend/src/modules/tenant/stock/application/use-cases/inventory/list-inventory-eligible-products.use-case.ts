import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import { signedMovementDelta } from "../../../domain/lote-stock.service";
import { readLoteTotal } from "../../../domain/lote-stock-read.util";

type ListEligibleProductsInput = {
  query?: string;
  categoriaId?: string;
  estadoSanitario?: string;
  page?: number;
  pageSize?: number;
};

function toNumber(value: unknown): number {
  if (value == null) return 0;
  if (typeof value === "number") return value;
  return Number(value) || 0;
}

/** Soma stock por lote a partir dos movimentos (fonte de verdade). */
async function stockByLoteIds(
  prisma: any,
  loteIds: bigint[],
): Promise<Map<string, number>> {
  const result = new Map<string, number>();
  if (loteIds.length === 0) return result;

  for (const id of loteIds) {
    result.set(id.toString(), 0);
  }

  const movements = await prisma.estoqueMovimento.findMany({
    where: {
      loteId: { in: loteIds },
      deletedAt: null,
    },
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
    select: {
      loteId: true,
      tipo: true,
      quantidade: true,
      estoqueAnterior: true,
      estoqueFinal: true,
    },
  });

  for (const movement of movements) {
    if (movement.loteId == null) continue;
    const key = movement.loteId.toString();
    const prev = result.get(key) ?? 0;
    result.set(key, prev + signedMovementDelta(movement));
  }

  for (const [key, value] of result) {
    result.set(key, Math.max(0, value));
  }

  return result;
}

export class ListInventoryEligibleProductsUseCase {
  async execute(input: ListEligibleProductsInput = {}) {
    const prisma = getPrisma() as any;
    const query = input.query?.trim() || undefined;
    const estadoSanitario = (input.estadoSanitario?.trim() || "VALIDO").toUpperCase();
    const page = Math.max(1, input.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, input.pageSize ?? 20));
    const categoriaId = input.categoriaId ? BigInt(input.categoriaId) : undefined;

    const loteWhere: Record<string, unknown> = {
      deletedAt: null,
      ativo: true,
      estadoSanitario,
    };

    const produtoWhere: Record<string, unknown> = {
      ativo: true,
      deletedAt: null,
      ...(categoriaId ? { categoriaId } : {}),
      lotes: { some: loteWhere },
    };

    if (query) {
      produtoWhere.OR = [
        { nomeComercial: { contains: query } },
        { nomeGenerico: { contains: query } },
        { barcode: { contains: query } },
        { dosagem: { contains: query } },
        { forma: { contains: query } },
        ...(/^\d+$/.test(query) ? [{ id: BigInt(query) }] : []),
      ];
    }

    const [totalCount, produtos] = await Promise.all([
      prisma.produto.count({ where: produtoWhere }),
      prisma.produto.findMany({
        where: produtoWhere,
        select: {
          id: true,
          nomeComercial: true,
          nomeGenerico: true,
          dosagem: true,
          forma: true,
          barcode: true,
          categoria: { select: { id: true, nome: true } },
          lotes: {
            where: loteWhere,
            select: {
              id: true,
              estadoSanitario: true,
              quantidadeQuarentena: true,
              stockBalance: {
                select: {
                  quantidadeTotal: true,
                  quantidadeDisponivel: true,
                },
              },
            },
          },
        },
        orderBy: [{ nomeComercial: "asc" }, { id: "asc" }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    const allLoteIds = produtos.flatMap((produto: any) =>
      (produto.lotes ?? []).map((lote: { id: bigint }) => lote.id),
    );
    const stockPorLote = await stockByLoteIds(prisma, allLoteIds);

    const items = produtos.map((produto: any) => {
      const lotes = produto.lotes ?? [];
      const stockAtual = lotes.reduce(
        (
          sum: number,
          lote: {
            id: bigint;
            stockBalance?: {
              quantidadeTotal?: unknown;
              quantidadeDisponivel?: unknown;
            } | null;
            quantidadeQuarentena?: unknown;
          },
        ) => {
          const fromMovements = stockPorLote.get(lote.id.toString());
          if (fromMovements != null && fromMovements > 0) {
            return sum + fromMovements;
          }
          // Fallback: cache LoteStockBalance (pode estar desactualizado a 0).
          return sum + readLoteTotal(lote);
        },
        0,
      );

      return {
        id: produto.id.toString(),
        nomeComercial: produto.nomeComercial,
        nomeGenerico: produto.nomeGenerico ?? null,
        dosagem: produto.dosagem ?? null,
        forma: produto.forma ?? null,
        barcode: produto.barcode ?? null,
        categoriaId: produto.categoria?.id?.toString() ?? null,
        categoriaNome: produto.categoria?.nome ?? null,
        estadoSanitario,
        stockAtual: toNumber(stockAtual),
        lotesCount: lotes.length,
      };
    });

    return {
      items,
      page,
      pageSize,
      totalCount,
      hasMore: page * pageSize < totalCount,
      summary: {
        produtos: totalCount,
        stockTotal: items.reduce(
          (sum: number, item: { stockAtual: number }) => sum + item.stockAtual,
          0,
        ),
      },
    };
  }
}

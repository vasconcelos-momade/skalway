/**
 * Stock por lote: EstoqueMovimento é a fonte de verdade;
 * LoteStockBalance é cache de leitura (total, disponível).
 */

import { FEFO_LOTE_FILTER } from "./fefo-lote.service";
import { startOfUtcDay } from "./expiry-date.util";
import type { FefoLoteRow } from "./lote.types";

type LoteRow = {
  id: bigint;
  numeroLote: string;
  dataValidade: Date;
  quantidadeQuarentena?: unknown;
  precoCompra: unknown;
  precoVenda?: unknown | null;
};

export type LoteStockTx = {
  lote?: {
    findFirst?: (args: {
      where: Record<string, unknown>;
      select?: Record<string, boolean>;
    }) => Promise<LoteRow | null>;
    findMany: (args: {
      where: Record<string, unknown>;
      orderBy?: Array<Record<string, "asc" | "desc">> | Record<string, "asc" | "desc">;
      select?: Record<string, unknown>;
    }) => Promise<LoteRow[]>;
  };
  estoqueMovimento?: {
    findFirst?: (args: {
      where: Record<string, unknown>;
      orderBy?:
        | Array<Record<string, "asc" | "desc">>
        | Record<string, "asc" | "desc">;
      select?: Record<string, boolean>;
    }) => Promise<{
      tipo?: string;
      quantidade?: unknown;
      estoqueAnterior?: unknown;
      estoqueFinal?: unknown;
    } | null>;
    findMany: (args: {
      where: Record<string, unknown>;
      orderBy?:
        | Array<Record<string, "asc" | "desc">>
        | Record<string, "asc" | "desc">;
      select?: Record<string, boolean>;
    }) => Promise<
      Array<{
        loteId?: bigint | null;
        tipo: string;
        quantidade: unknown;
        estoqueAnterior?: unknown;
        estoqueFinal?: unknown;
        createdAt?: Date;
        id?: bigint;
      }>
    >;
  };
  loteStockBalance?: {
    findUnique: (args: {
      where: { loteId: bigint };
    }) => Promise<{
      quantidadeTotal: unknown;
      quantidadeDisponivel: unknown;
    } | null>;
    upsert: (args: {
      where: { loteId: bigint };
      create: Record<string, unknown>;
      update: Record<string, unknown>;
    }) => Promise<unknown>;
  };
};

function toNumber(value: unknown): number {
  if (value == null) return 0;
  if (typeof value === "number") return value;
  return Number(value) || 0;
}

/** Delta assinado de um movimento (produto ou lote). */
export function signedMovementDelta(movement: {
  tipo: string;
  quantidade: unknown;
  estoqueAnterior?: unknown;
  estoqueFinal?: unknown;
}): number {
  const qty = toNumber(movement.quantidade);
  switch (movement.tipo) {
    case "ENTRADA":
    case "COMPRA":
    case "DEVOLUCAO":
      return qty;
    case "SAIDA":
    case "INCINERACAO":
      return -qty;
    case "QUARENTENA":
      // Quarentena não altera stock físico — só quantidadeQuarentena no lote.
      return 0;
    case "AJUSTE":
      return (
        toNumber(movement.estoqueFinal) - toNumber(movement.estoqueAnterior)
      );
    default:
      return 0;
  }
}

/**
 * Total físico do lote a partir dos movimentos (fonte de verdade).
 *
 * Usa a soma de deltas por lote — não o último estoqueFinal, porque vários
 * writers (POS/FEFO, quarentena) gravaram o saldo de produto nesse campo.
 */
export async function getLoteQuantidadeFromMovements(
  tx: LoteStockTx,
  loteId: bigint,
): Promise<number> {
  if (!tx.estoqueMovimento?.findMany) return 0;

  const movements = await tx.estoqueMovimento.findMany({
    where: { loteId, deletedAt: null },
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
    select: {
      tipo: true,
      quantidade: true,
      estoqueAnterior: true,
      estoqueFinal: true,
    },
  });

  if (movements.length === 0) return 0;

  return Math.max(
    0,
    movements.reduce<number>((sum, m) => sum + signedMovementDelta(m), 0),
  );
}

/**
 * Stock (total + disponível) para vários lotes a partir de EstoqueMovimento.
 * Fonte de verdade — preferir a cache LoteStockBalance desactualizada.
 */
export async function getLoteStockMapFromMovements(
  tx: LoteStockTx,
  lotes: Array<{ id: bigint; quantidadeQuarentena?: unknown }>,
): Promise<Map<string, { total: number; disponivel: number }>> {
  const result = new Map<string, { total: number; disponivel: number }>();
  if (lotes.length === 0 || !tx.estoqueMovimento?.findMany) {
    return result;
  }

  for (const lote of lotes) {
    result.set(lote.id.toString(), {
      total: 0,
      disponivel: loteQuantidadeDisponivelFromTotal(0, lote.quantidadeQuarentena),
    });
  }

  const loteIds = lotes.map((lote) => lote.id);
  const movements = await tx.estoqueMovimento.findMany({
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

  const totals = new Map<string, number>();
  for (const id of loteIds) {
    totals.set(id.toString(), 0);
  }

  for (const movement of movements) {
    if (movement.loteId == null) continue;
    const key = movement.loteId.toString();
    totals.set(key, (totals.get(key) ?? 0) + signedMovementDelta(movement));
  }

  const quarentenaById = new Map(
    lotes.map((lote) => [lote.id.toString(), lote.quantidadeQuarentena]),
  );

  for (const [key, rawTotal] of totals) {
    const total = Math.max(0, rawTotal);
    const disponivel = loteQuantidadeDisponivelFromTotal(
      total,
      quarentenaById.get(key),
    );
    result.set(key, { total, disponivel });
  }

  return result;
}

export function loteQuantidadeDisponivelFromTotal(
  quantidadeTotal: number,
  quantidadeQuarentena?: unknown,
): number {
  return Math.max(0, quantidadeTotal - toNumber(quantidadeQuarentena));
}

/** Quantidade vendável do lote (movimentos − quarentena). */
export async function getLoteQuantidadeDisponivel(
  tx: LoteStockTx,
  lote: { id: bigint; quantidadeQuarentena?: unknown },
): Promise<number> {
  const total = await getLoteQuantidadeFromMovements(tx, lote.id);
  return loteQuantidadeDisponivelFromTotal(total, lote.quantidadeQuarentena);
}

/**
 * Actualiza LoteStockBalance a partir de EstoqueMovimento.
 */
export async function syncLoteStockBalanceCache(
  tx: LoteStockTx,
  lote: { id: bigint; quantidadeQuarentena?: unknown },
): Promise<{ total: number; disponivel: number }> {
  const total = await getLoteQuantidadeFromMovements(tx, lote.id);
  const disponivel = loteQuantidadeDisponivelFromTotal(
    total,
    lote.quantidadeQuarentena,
  );

  if (tx.loteStockBalance?.upsert) {
    await tx.loteStockBalance.upsert({
      where: { loteId: lote.id },
      create: {
        loteId: lote.id,
        quantidadeTotal: total,
        quantidadeDisponivel: disponivel,
      },
      update: {
        quantidadeTotal: total,
        quantidadeDisponivel: disponivel,
      },
    });
  }

  return { total, disponivel };
}

export type FefoAllocation = {
  lote: FefoLoteRow;
  quantidade: number;
};

/**
 * Aloca quantidade em lotes FEFO (dataValidade ASC, createdAt ASC).
 * Requer lock pessimista nos lotes antes de chamar.
 */
export async function allocateFefoLotes(
  tx: LoteStockTx,
  produtoId: bigint,
  quantidade: number,
): Promise<FefoAllocation[]> {
  if (!tx.lote?.findMany) {
    throw new Error("Transação sem acesso a lotes");
  }

  const lotes = await tx.lote.findMany({
    where: {
      produtoId,
      ...FEFO_LOTE_FILTER,
      dataValidade: { gte: startOfUtcDay() },
    },
    orderBy: [{ dataValidade: "asc" }, { createdAt: "asc" }],
    select: {
      id: true,
      numeroLote: true,
      dataValidade: true,
      quantidadeQuarentena: true,
      precoCompra: true,
      precoVenda: true,
    },
  });

  const allocations: FefoAllocation[] = [];
  let remaining = quantidade;

  for (const lote of lotes) {
    if (remaining <= 0) break;

    const disponivel = await getLoteQuantidadeDisponivel(tx, lote);
    if (disponivel <= 0) continue;

    const take = Math.min(disponivel, remaining);
    allocations.push({ lote: lote as FefoLoteRow, quantidade: take });
    remaining -= take;
  }

  if (remaining > 0) {
    throw new Error(
      `Stock insuficiente em lotes FEFO para o produto ${produtoId}`,
    );
  }

  return allocations;
}

/** Soma stock vendável de todos os lotes elegíveis FEFO do produto. */
export async function getSellableQuantityFromLoteMovements(
  tx: LoteStockTx,
  produtoId: bigint,
): Promise<number> {
  if (!tx.lote?.findMany) return 0;

  const lotes = await tx.lote.findMany({
    where: {
      produtoId,
      ...FEFO_LOTE_FILTER,
      dataValidade: { gte: startOfUtcDay() },
    },
    select: { id: true, quantidadeQuarentena: true },
  });

  let total = 0;
  for (const lote of lotes) {
    total += await getLoteQuantidadeDisponivel(tx, lote);
  }
  return total;
}

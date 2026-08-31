import { daysAgo, endOfDay, round2, startOfDay, toNumber } from "../../dashboard/application/dashboard-date.util";
import { syncStockBalanceCache } from "./produto-stock.service";
import { resolvePrincipalSupplierId } from "./purchase-supplier.util";

export const DEFAULT_COVERAGE_DAYS = 30;
export const CONSUMPTION_PERIOD_DAYS = 30;

export type PurchaseSuggestionCalculationInput = {
  estoqueAtual: number;
  estoqueMinimo: number;
  totalSaidasPeriodo: number;
  diasDoPeriodo?: number;
  diasReposicao?: number;
};

export type PurchaseSuggestionMetrics = {
  consumoMedioDiario: number;
  totalSaidasPeriodo: number;
  quantidadeSugerida: number;
};

type PurchaseSuggestionTx = {
  produto?: {
    findUnique: (args: {
      where: { id: bigint };
      select?: Record<string, boolean | object>;
    }) => Promise<{
      id: bigint;
      estoqueMinimo: unknown;
      ativo: boolean;
      deletedAt: Date | null;
      stockBalance?: { quantidadeDisponivel: unknown } | null;
      fornecedores?: Array<{
        fornecedorPrincipal: boolean;
        fornecedorId: bigint;
      }>;
    } | null>;
  };
  purchaseSuggestion?: {
    findUnique: (args: {
      where: { produtoId: bigint };
    }) => Promise<{
      id: bigint;
      origem: "AUTOMATICA" | "MANUAL";
      quantidadeSugerida: unknown;
      quantidadeAprovada?: unknown;
      supplierId?: bigint | null;
    } | null>;
    upsert: (args: {
      where: { produtoId: bigint };
      create: Record<string, unknown>;
      update: Record<string, unknown>;
    }) => Promise<unknown>;
    delete: (args: { where: { produtoId: bigint } }) => Promise<unknown>;
    deleteMany: (args: { where: Record<string, unknown> }) => Promise<unknown>;
  };
  estoqueMovimento?: {
    findFirst?: (args: {
      where: Record<string, unknown>;
      select?: Record<string, boolean>;
    }) => Promise<{ id: bigint } | null>;
    findMany: (args: {
      where: Record<string, unknown>;
      select?: Record<string, boolean>;
    }) => Promise<Array<{ quantidade: unknown }>>;
  };
};

export function roundSuggestionInteger(value: number): number {
  return Math.round(toNumber(value));
}

const PURCHASE_SUGGESTION_APPROVAL_ROLES = new Set([
  "GERENTE",
  "DIRETOR_TECNICO",
  "ADMIN",
]);

export function canApprovePurchaseSuggestionQuantity(
  role: string | null | undefined,
): boolean {
  if (!role) return false;
  return PURCHASE_SUGGESTION_APPROVAL_ROLES.has(role);
}

export function formatSuggestionInteger(value: unknown): string {
  return String(roundSuggestionInteger(toNumber(value)));
}

/** Ex.: `Aminofilina 500mg Cápsulas` */
export function formatProductDisplayLabel(input: {
  nomeComercial?: string | null;
  dosagem?: string | null;
  forma?: string | null;
}): string {
  const parts = [
    input.nomeComercial?.trim(),
    input.dosagem?.trim(),
    input.forma?.trim(),
  ].filter((part): part is string => Boolean(part && part.length > 0));
  return parts.length > 0 ? parts.join(" ") : "—";
}

export function sumSaidasFromMovements(
  movements: Array<{ quantidade: unknown }>,
): number {
  return roundSuggestionInteger(
    movements.reduce((sum, row) => sum + Math.abs(toNumber(row.quantidade)), 0),
  );
}

export function calculateConsumoMedioDiario(
  totalSaidasPeriodo: number,
  diasDoPeriodo = CONSUMPTION_PERIOD_DAYS,
): number {
  const dias = diasDoPeriodo > 0 ? diasDoPeriodo : CONSUMPTION_PERIOD_DAYS;
  const total = roundSuggestionInteger(totalSaidasPeriodo);
  if (total <= 0) {
    return 0;
  }
  return round2(total / dias);
}

/**
 * Única implementação da fórmula de quantidade sugerida automática.
 * quantidadeSugerida = max(0, consumoMedioDiario * diasReposicao + estoqueMinimo - estoqueAtual)
 */
export function calculateQuantidadeSugerida(
  input: PurchaseSuggestionCalculationInput,
): number {
  const diasDoPeriodo = input.diasDoPeriodo ?? CONSUMPTION_PERIOD_DAYS;
  const diasReposicao = input.diasReposicao ?? DEFAULT_COVERAGE_DAYS;
  const consumoMedioDiario = calculateConsumoMedioDiario(
    input.totalSaidasPeriodo,
    diasDoPeriodo,
  );
  const demandaReposicao = consumoMedioDiario * diasReposicao;
  const estoqueMinimo = round2(toNumber(input.estoqueMinimo));
  const estoqueAtual = round2(toNumber(input.estoqueAtual));
  const bruto = demandaReposicao + estoqueMinimo - estoqueAtual;

  return roundSuggestionInteger(Math.max(0, bruto));
}

export function buildAutomaticPurchaseSuggestionMetrics(
  input: PurchaseSuggestionCalculationInput,
): PurchaseSuggestionMetrics {
  const totalSaidasPeriodo = roundSuggestionInteger(input.totalSaidasPeriodo);
  const diasDoPeriodo = input.diasDoPeriodo ?? CONSUMPTION_PERIOD_DAYS;

  return {
    totalSaidasPeriodo,
    consumoMedioDiario: calculateConsumoMedioDiario(
      totalSaidasPeriodo,
      diasDoPeriodo,
    ),
    quantidadeSugerida: calculateQuantidadeSugerida({
      ...input,
      totalSaidasPeriodo,
      diasDoPeriodo,
    }),
  };
}

function formatDisplayDate(date: Date): string {
  const day = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const year = String(date.getFullYear());
  return `${day}/${month}/${year}`;
}

export type PurchaseSuggestionPeriodRange = {
  inicio: Date;
  fim: Date;
  diasDoPeriodo: number;
  periodoInicio: string;
  periodoFim: string;
  periodoLabel: string;
  coberturaDias: number;
};

export function resolvePurchaseSuggestionPeriod(input?: {
  dataInicio?: Date | string;
  dataFim?: Date | string;
  referenceDate?: Date;
}): PurchaseSuggestionPeriodRange {
  const fim = startOfDay(
    input?.dataFim != null
      ? new Date(input.dataFim)
      : (input?.referenceDate ?? new Date()),
  );
  const inicio = startOfDay(
    input?.dataInicio != null
      ? new Date(input.dataInicio)
      : daysAgo(CONSUMPTION_PERIOD_DAYS, fim),
  );
  const diasDoPeriodo = Math.max(
    1,
    Math.floor((fim.getTime() - inicio.getTime()) / (1000 * 60 * 60 * 24)) + 1,
  );

  return {
    inicio,
    fim,
    diasDoPeriodo,
    periodoInicio: formatDisplayDate(inicio),
    periodoFim: formatDisplayDate(fim),
    periodoLabel: `${formatDisplayDate(inicio)} - ${formatDisplayDate(fim)}`,
    coberturaDias: DEFAULT_COVERAGE_DAYS,
  };
}

async function hasStockMovementHistory(
  tx: PurchaseSuggestionTx,
  produtoId: bigint,
): Promise<boolean> {
  if (!tx.estoqueMovimento?.findFirst) {
    return false;
  }

  const movement = await tx.estoqueMovimento.findFirst({
    where: { produtoId, deletedAt: null },
    select: { id: true },
  });

  return movement != null;
}

async function loadTotalSaidasPeriodo(
  tx: PurchaseSuggestionTx,
  produtoId: bigint,
  period?: PurchaseSuggestionPeriodRange,
): Promise<number> {
  if (!tx.estoqueMovimento?.findMany) {
    return 0;
  }

  const activePeriod = period ?? resolvePurchaseSuggestionPeriod();

  const movements = await tx.estoqueMovimento.findMany({
    where: {
      produtoId,
      deletedAt: null,
      tipo: "SAIDA",
      createdAt: {
        gte: activePeriod.inicio,
        lte: endOfDay(activePeriod.fim),
      },
    },
    select: { quantidade: true },
  });

  return sumSaidasFromMovements(movements);
}

function resolveEstoqueAtual(
  produto: { stockBalance?: { quantidadeDisponivel: unknown } | null },
  disponivelFromSync?: number,
): number {
  if (disponivelFromSync != null) {
    return round2(disponivelFromSync);
  }
  return round2(toNumber(produto.stockBalance?.quantidadeDisponivel));
}

/**
 * Recalcula ou remove a sugestão automática após alteração de stock.
 * Itens manuais não são removidos automaticamente quando o stock sobe.
 */
export async function syncPurchaseSuggestionAfterStockChange(
  tx: PurchaseSuggestionTx,
  produtoId: bigint,
  disponivelFromSync?: number,
  period?: PurchaseSuggestionPeriodRange,
): Promise<void> {
  const db = tx as PurchaseSuggestionTx & {
    purchaseSuggestion?: PurchaseSuggestionTx["purchaseSuggestion"];
    produto?: PurchaseSuggestionTx["produto"];
    estoqueMovimento?: PurchaseSuggestionTx["estoqueMovimento"];
  };

  if (!db.purchaseSuggestion?.upsert || !db.produto?.findUnique) {
    return;
  }

  const produto = await db.produto.findUnique({
    where: { id: produtoId },
    select: {
      id: true,
      estoqueMinimo: true,
      ativo: true,
      deletedAt: true,
      stockBalance: { select: { quantidadeDisponivel: true } },
      fornecedores: {
        select: { fornecedorPrincipal: true, fornecedorId: true },
      },
    },
  });

  if (!produto || !produto.ativo || produto.deletedAt) {
    await db.purchaseSuggestion.deleteMany({ where: { produtoId } });
    return;
  }

  const supplierId = resolvePrincipalSupplierId(produto.fornecedores);

  const estoqueAtual = resolveEstoqueAtual(produto, disponivelFromSync);
  const estoqueMinimo = round2(toNumber(produto.estoqueMinimo));
  const existing = await db.purchaseSuggestion.findUnique({ where: { produtoId } });
  const isManual = existing?.origem === "MANUAL";
  const manualSupplierId = isManual ? existing?.supplierId ?? supplierId : supplierId;

  if (estoqueMinimo <= 0) {
    if (existing?.origem !== "MANUAL") {
      if (existing) {
        await db.purchaseSuggestion.delete({ where: { produtoId } });
      }
      return;
    }
  }

  const temHistoricoMovimentacao = await hasStockMovementHistory(db, produtoId);

  const activePeriod = period ?? resolvePurchaseSuggestionPeriod();
  const totalSaidasPeriodo = await loadTotalSaidasPeriodo(db, produtoId, activePeriod);
  const metrics = buildAutomaticPurchaseSuggestionMetrics({
    estoqueAtual,
    estoqueMinimo,
    totalSaidasPeriodo,
    diasDoPeriodo: activePeriod.diasDoPeriodo,
  });

  if (estoqueAtual > estoqueMinimo) {
    if (isManual) {
      await db.purchaseSuggestion.upsert({
        where: { produtoId },
        create: {
          produtoId,
          supplierId: manualSupplierId,
          quantidadeAtual: estoqueAtual,
          estoqueMinimo,
          consumoMedioDiario: metrics.consumoMedioDiario,
          totalSaidasPeriodo: metrics.totalSaidasPeriodo,
          quantidadeSugerida: metrics.quantidadeSugerida,
          coberturaDias: DEFAULT_COVERAGE_DAYS,
          origem: "MANUAL",
        },
        update: {
          quantidadeAtual: estoqueAtual,
          estoqueMinimo,
          consumoMedioDiario: metrics.consumoMedioDiario,
          totalSaidasPeriodo: metrics.totalSaidasPeriodo,
          quantidadeSugerida: metrics.quantidadeSugerida,
        },
      });
      return;
    }

    if (existing) {
      await db.purchaseSuggestion.delete({ where: { produtoId } });
    }
    return;
  }

  if (isManual) {
    await db.purchaseSuggestion.upsert({
      where: { produtoId },
      create: {
        produtoId,
        supplierId: manualSupplierId,
        quantidadeAtual: estoqueAtual,
        estoqueMinimo,
        consumoMedioDiario: metrics.consumoMedioDiario,
        totalSaidasPeriodo: metrics.totalSaidasPeriodo,
        quantidadeSugerida: metrics.quantidadeSugerida,
        coberturaDias: DEFAULT_COVERAGE_DAYS,
        origem: "MANUAL",
      },
      update: {
        quantidadeAtual: estoqueAtual,
        estoqueMinimo,
        consumoMedioDiario: metrics.consumoMedioDiario,
        totalSaidasPeriodo: metrics.totalSaidasPeriodo,
        quantidadeSugerida: metrics.quantidadeSugerida,
      },
    });
    return;
  }

  if (!temHistoricoMovimentacao) {
    if (existing) {
      await db.purchaseSuggestion.delete({ where: { produtoId } });
    }
    return;
  }

  if (metrics.quantidadeSugerida <= 0) {
    if (existing) {
      await db.purchaseSuggestion.delete({ where: { produtoId } });
    }
    return;
  }

  await db.purchaseSuggestion.upsert({
    where: { produtoId },
    create: {
      produtoId,
      supplierId,
      quantidadeAtual: estoqueAtual,
      estoqueMinimo,
      consumoMedioDiario: metrics.consumoMedioDiario,
      totalSaidasPeriodo: metrics.totalSaidasPeriodo,
      quantidadeSugerida: metrics.quantidadeSugerida,
      quantidadeAprovada: metrics.quantidadeSugerida,
      coberturaDias: DEFAULT_COVERAGE_DAYS,
      origem: "AUTOMATICA",
    },
    update: {
      supplierId,
      quantidadeAtual: estoqueAtual,
      estoqueMinimo,
      consumoMedioDiario: metrics.consumoMedioDiario,
      totalSaidasPeriodo: metrics.totalSaidasPeriodo,
      quantidadeSugerida: metrics.quantidadeSugerida,
      coberturaDias: DEFAULT_COVERAGE_DAYS,
    },
  });
}

export async function refreshAllPurchaseSuggestions(
  prisma: {
    produto: {
      findMany: (args: Record<string, unknown>) => Promise<Array<{ id: bigint }>>;
    };
    $transaction: <T>(fn: (tx: PurchaseSuggestionTx) => Promise<T>) => Promise<T>;
  },
  input?: { dataInicio: Date | string; dataFim: Date | string },
): Promise<{
  processed: number;
  periodo: PurchaseSuggestionPeriodRange;
}> {
  const periodo = resolvePurchaseSuggestionPeriod(input);

  const produtos = await prisma.produto.findMany({
    where: {
      deletedAt: null,
      ativo: true,
      estoqueMinimo: { gt: 0 },
      movimentos: { some: { deletedAt: null } },
    },
    select: { id: true },
    orderBy: { id: "asc" },
  });

  for (const produto of produtos) {
    await prisma.$transaction(async (tx) => {
      await syncStockBalanceCache(tx as any, produto.id);
      await syncPurchaseSuggestionAfterStockChange(tx, produto.id, undefined, periodo);
    });
  }

  return {
    processed: produtos.length,
    periodo,
  };
}

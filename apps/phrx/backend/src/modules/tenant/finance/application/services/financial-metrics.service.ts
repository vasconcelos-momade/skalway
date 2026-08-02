import { getPrisma } from "../../../../../infrastructure/prisma/tenant-prisma.factory";

const FATURA_VENDA_WHERE = {
  deletedAt: null,
  estado: { in: ["EMITIDA", "PAGA", "PARCIAL"] },
} as const;

export type FinancialMetricsRange = {
  from: Date;
  to: Date;
  /** Quando definido, restringe métricas à actividade deste utilizador (data scope OWN). */
  userId?: string | null;
};

function userIdFilter(range: FinancialMetricsRange): { userId?: bigint } {
  return range.userId ? { userId: BigInt(range.userId) } : {};
}

type TxLike = any;

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

function toNumber(value: unknown): number {
  if (value == null) return 0;
  if (typeof value === "number") return value;
  return Number(value) || 0;
}

export type DreMetrics = {
  receita: number;
  faturamento: number;
  custos: number;
  lucroBruto: number;
  despesas: number;
  lucroLiquido: number;
  margem: number;
  margemLucro: number;
  ticketMedio: number;
  numVendas: number;
};

export type CashFlowMetrics = {
  vendas: number;
  /** Saídas de caixa: DESPESA_OPERACIONAL + COMPRA_ESTOQUE (fórmula de saldo). */
  despesas: number;
  despesasOperacionais: number;
  comprasEstoque: number;
  suprimentos: number;
  sangrias: number;
  estornos: number;
  estornosSigned: number;
  saldoInicial: number;
  saldoFinal: number;
  saldoAtual: number;
  fluxoCaixa: number;
  entradas: number;
  saidas: number;
};

export type DreFlowPoint = {
  data?: string;
  mes?: string;
  receitas: number;
  despesas: number;
  saldo: number;
};

export class FinancialMetricsService {
  private readonly prisma: TxLike;

  constructor(prisma?: TxLike) {
    this.prisma = prisma ?? (getPrisma() as any);
  }

  async calculateRevenue(range: FinancialMetricsRange, tx?: TxLike): Promise<number> {
    const prisma = tx ?? this.prisma;
    const result = await prisma.fatura.aggregate({
      where: {
        ...FATURA_VENDA_WHERE,
        ...userIdFilter(range),
        createdAt: { gte: range.from, lte: range.to },
      },
      _sum: { total: true },
    });
    return round2(toNumber(result._sum.total));
  }

  async calculateSalesCount(range: FinancialMetricsRange, tx?: TxLike): Promise<number> {
    const prisma = tx ?? this.prisma;
    return prisma.fatura.count({
      where: {
        ...FATURA_VENDA_WHERE,
        ...userIdFilter(range),
        createdAt: { gte: range.from, lte: range.to },
      },
    });
  }

  async calculateCostOfGoodsSold(range: FinancialMetricsRange, tx?: TxLike): Promise<number> {
    const prisma = tx ?? this.prisma;
    const rows = await prisma.faturaItem.findMany({
      where: {
        fatura: {
          ...FATURA_VENDA_WHERE,
          ...userIdFilter(range),
          createdAt: { gte: range.from, lte: range.to },
        },
      },
      select: {
        quantidade: true,
        custoUnitario: true,
      },
    });
    return round2(
      rows.reduce(
        (sum: number, row: { quantidade: unknown; custoUnitario: unknown }) =>
          sum + toNumber(row.quantidade) * toNumber(row.custoUnitario),
        0,
      ),
    );
  }

  async calculateOperationalExpenses(
    range: FinancialMetricsRange,
    tx?: TxLike,
  ): Promise<number> {
    const prisma = tx ?? this.prisma;
    const result = await prisma.financialMovement.aggregate({
      where: {
        deletedAt: null,
        type: "EXPENSE",
        createdAt: { gte: range.from, lte: range.to },
      },
      _sum: { amount: true },
    });
    return round2(toNumber(result._sum.amount));
  }

  async calculateGrossProfit(range: FinancialMetricsRange, tx?: TxLike): Promise<number> {
    const [receita, custos] = await Promise.all([
      this.calculateRevenue(range, tx),
      this.calculateCostOfGoodsSold(range, tx),
    ]);
    return round2(receita - custos);
  }

  async calculateNetProfit(range: FinancialMetricsRange, tx?: TxLike): Promise<number> {
    const [lucroBruto, despesas] = await Promise.all([
      this.calculateGrossProfit(range, tx),
      this.calculateOperationalExpenses(range, tx),
    ]);
    return round2(lucroBruto - despesas);
  }

  async calculateMargin(range: FinancialMetricsRange, tx?: TxLike): Promise<number> {
    const [receita, lucroLiquido] = await Promise.all([
      this.calculateRevenue(range, tx),
      this.calculateNetProfit(range, tx),
    ]);
    return receita > 0 ? round2((lucroLiquido / receita) * 100) : 0;
  }

  async calculateAverageTicket(range: FinancialMetricsRange, tx?: TxLike): Promise<number> {
    const [receita, numVendas] = await Promise.all([
      this.calculateRevenue(range, tx),
      this.calculateSalesCount(range, tx),
    ]);
    return numVendas > 0 ? round2(receita / numVendas) : 0;
  }

  async calculateDreMetrics(range: FinancialMetricsRange, tx?: TxLike): Promise<DreMetrics> {
    const [receita, custos, despesas, numVendas] = await Promise.all([
      this.calculateRevenue(range, tx),
      this.calculateCostOfGoodsSold(range, tx),
      this.calculateOperationalExpenses(range, tx),
      this.calculateSalesCount(range, tx),
    ]);
    const lucroBruto = round2(receita - custos);
    const lucroLiquido = round2(lucroBruto - despesas);
    const margem = receita > 0 ? round2((lucroLiquido / receita) * 100) : 0;
    const ticketMedio = numVendas > 0 ? round2(receita / numVendas) : 0;

    return {
      receita,
      faturamento: receita,
      custos,
      lucroBruto,
      despesas,
      lucroLiquido,
      margem,
      margemLucro: margem,
      ticketMedio,
      numVendas,
    };
  }

  async calculateCashFlow(range: FinancialMetricsRange, tx?: TxLike): Promise<CashFlowMetrics> {
    const prisma = tx ?? this.prisma;
    const scopedUser = userIdFilter(range);
    const caixaMovimentoPeriod = {
      deletedAt: null,
      createdAt: { gte: range.from, lte: range.to },
      ...scopedUser,
    };

    const [
      vendasAgg,
      despesasOperacionaisAgg,
      comprasEstoqueAgg,
      suprimentosAgg,
      sangriasAgg,
      estornosAgg,
      estornosRows,
      saldoCaixaAgg,
    ] = await prisma.$transaction([
      prisma.caixaMovimento.aggregate({
        where: { ...caixaMovimentoPeriod, tipo: "VENDA" },
        _sum: { valor: true },
      }),
      prisma.caixaMovimento.aggregate({
        where: { ...caixaMovimentoPeriod, tipo: "DESPESA_OPERACIONAL" },
        _sum: { valor: true },
      }),
      prisma.caixaMovimento.aggregate({
        where: { ...caixaMovimentoPeriod, tipo: "COMPRA_ESTOQUE" },
        _sum: { valor: true },
      }),
      prisma.caixaMovimento.aggregate({
        where: { ...caixaMovimentoPeriod, tipo: "SUPRIMENTO" },
        _sum: { valor: true },
      }),
      prisma.caixaMovimento.aggregate({
        where: { ...caixaMovimentoPeriod, tipo: "SANGRIA" },
        _sum: { valor: true },
      }),
      prisma.caixaMovimento.aggregate({
        where: { ...caixaMovimentoPeriod, tipo: "ESTORNO" },
        _sum: { valor: true },
      }),
      prisma.caixaMovimento.findMany({
        where: { ...caixaMovimentoPeriod, tipo: "ESTORNO" },
        select: { saldoAnterior: true, saldoFinal: true },
      }),
      prisma.cashBalance.aggregate({ _sum: { saldoTotal: true } }),
    ]);

    const vendas = round2(toNumber(vendasAgg._sum.valor));
    const despesasOperacionais = round2(toNumber(despesasOperacionaisAgg._sum.valor));
    const comprasEstoque = round2(toNumber(comprasEstoqueAgg._sum.valor));
    // Saídas de caixa (fórmula): operacionais + compra de estoque
    const despesas = round2(despesasOperacionais + comprasEstoque);
    const suprimentos = round2(toNumber(suprimentosAgg._sum.valor));
    const sangrias = round2(toNumber(sangriasAgg._sum.valor));
    const estornos = round2(toNumber(estornosAgg._sum.valor));
    const estornosSigned = round2(
      (estornosRows as Array<{ saldoAnterior: unknown; saldoFinal: unknown }>).reduce(
        (acc, row) => acc + (toNumber(row.saldoFinal) - toNumber(row.saldoAnterior)),
        0,
      ),
    );

    let saldoFinal = round2(toNumber(saldoCaixaAgg._sum.saldoTotal));
    if (range.userId) {
      const [openSessao, scopedSaldoRow] = await Promise.all([
        prisma.caixaSessao.findFirst({
          where: {
            userId: BigInt(range.userId),
            status: "ABERTA",
            deletedAt: null,
          },
          select: { caixa: { select: { saldoAtual: true } } },
          orderBy: { openedAt: "desc" },
        }),
        prisma.caixaMovimento.findFirst({
          where: { deletedAt: null, userId: BigInt(range.userId) },
          orderBy: { createdAt: "desc" },
          select: { saldoFinal: true },
        }),
      ]);

      const sessaoSaldo = openSessao?.caixa?.saldoAtual;
      if (sessaoSaldo != null) {
        saldoFinal = round2(toNumber(sessaoSaldo));
      } else if (scopedSaldoRow?.saldoFinal != null) {
        saldoFinal = round2(toNumber(scopedSaldoRow.saldoFinal));
      } else {
        saldoFinal = round2(vendas + suprimentos - despesas - sangrias + estornosSigned);
      }
    }

    const saldoInicial = round2(
      saldoFinal - vendas - suprimentos + despesas + sangrias - estornosSigned,
    );
    const entradas = round2(vendas + suprimentos + Math.max(estornosSigned, 0));
    const saidas = round2(despesas + sangrias + Math.abs(Math.min(estornosSigned, 0)));
    const fluxoCaixa = round2(vendas + suprimentos - despesas - sangrias + estornosSigned);

    return {
      vendas,
      despesas,
      despesasOperacionais,
      comprasEstoque,
      suprimentos,
      sangrias,
      estornos,
      estornosSigned,
      saldoInicial,
      saldoFinal,
      saldoAtual: saldoFinal,
      fluxoCaixa,
      entradas,
      saidas,
    };
  }

  async getDailyDreFlow(
    chartFrom: Date,
    chartTo: Date,
    days: number,
    tx?: TxLike,
    userId?: string | null,
  ): Promise<DreFlowPoint[]> {
    const prisma = tx ?? this.prisma;
    const scoped = userId ? { userId: BigInt(userId) } : {};
    const [faturas, despesasRows] = await Promise.all([
      prisma.fatura.findMany({
        where: {
          ...FATURA_VENDA_WHERE,
          ...scoped,
          createdAt: { gte: chartFrom, lte: chartTo },
        },
        select: { createdAt: true, total: true },
      }),
      prisma.financialMovement.findMany({
        where: {
          deletedAt: null,
          type: "EXPENSE",
          ...scoped,
          createdAt: { gte: chartFrom, lte: chartTo },
        },
        select: { createdAt: true, amount: true },
      }),
    ]);

    return buildDailyDreFlow(faturas, despesasRows, chartFrom, days);
  }

  async getMonthlyDreFlow(
    chartTo: Date,
    months: number,
    tx?: TxLike,
  ): Promise<DreFlowPoint[]> {
    const prisma = tx ?? this.prisma;
    const chartFrom = new Date(chartTo.getFullYear(), chartTo.getMonth() - (months - 1), 1);
    const [faturas, despesasRows] = await Promise.all([
      prisma.fatura.findMany({
        where: {
          ...FATURA_VENDA_WHERE,
          createdAt: { gte: chartFrom, lte: chartTo },
        },
        select: { createdAt: true, total: true },
      }),
      prisma.financialMovement.findMany({
        where: {
          deletedAt: null,
          type: "EXPENSE",
          createdAt: { gte: chartFrom, lte: chartTo },
        },
        select: { createdAt: true, amount: true },
      }),
    ]);

    return buildMonthlyDreFlow(faturas, despesasRows, months, chartTo);
  }
}

function toIsoDate(date: Date): string {
  // Calendário local (TZ do processo) — alinhado com startOfDay / buckets diários.
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function buildDailyDreFlow(
  faturas: Array<{ createdAt: Date; total: unknown }>,
  despesasRows: Array<{ createdAt: Date; amount: unknown }>,
  from: Date,
  days: number,
): DreFlowPoint[] {
  const buckets = new Map<string, { receitas: number; despesas: number }>();
  for (let i = 0; i < days; i++) {
    const d = new Date(from);
    d.setDate(from.getDate() + i);
    buckets.set(toIsoDate(d), { receitas: 0, despesas: 0 });
  }

  for (const row of faturas) {
    const key = toIsoDate(new Date(row.createdAt));
    const bucket = buckets.get(key);
    if (!bucket) continue;
    bucket.receitas += toNumber(row.total);
  }

  for (const row of despesasRows) {
    const key = toIsoDate(new Date(row.createdAt));
    const bucket = buckets.get(key);
    if (!bucket) continue;
    bucket.despesas += toNumber(row.amount);
  }

  return [...buckets.entries()].map(([data, values]) => ({
    data,
    receitas: round2(values.receitas),
    despesas: round2(values.despesas),
    saldo: round2(values.receitas - values.despesas),
  }));
}

function buildMonthlyDreFlow(
  faturas: Array<{ createdAt: Date; total: unknown }>,
  despesasRows: Array<{ createdAt: Date; amount: unknown }>,
  months: number,
  referenceDate: Date,
): DreFlowPoint[] {
  const buckets = new Map<string, { receitas: number; despesas: number }>();
  for (let i = months - 1; i >= 0; i--) {
    const d = new Date(referenceDate.getFullYear(), referenceDate.getMonth() - i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    buckets.set(key, { receitas: 0, despesas: 0 });
  }

  for (const row of faturas) {
    const d = new Date(row.createdAt);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    const bucket = buckets.get(key);
    if (!bucket) continue;
    bucket.receitas += toNumber(row.total);
  }

  for (const row of despesasRows) {
    const d = new Date(row.createdAt);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    const bucket = buckets.get(key);
    if (!bucket) continue;
    bucket.despesas += toNumber(row.amount);
  }

  return [...buckets.entries()].map(([mes, values]) => ({
    mes,
    receitas: round2(values.receitas),
    despesas: round2(values.despesas),
    saldo: round2(values.receitas - values.despesas),
  }));
}

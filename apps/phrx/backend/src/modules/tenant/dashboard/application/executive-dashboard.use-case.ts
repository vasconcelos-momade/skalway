import { getPrisma } from "../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  endOfDay,
  endOfMonth,
  FATURA_VENDA_WHERE,
  round2,
  startOfDay,
  toIsoDate,
  toNumber,
} from "./dashboard-date.util";
import {
  percentGrowth,
  previousEquivalentPeriod,
  resolveDashboardPeriod,
  serializePeriodo,
} from "./dashboard-period.util";
import {
  buildPagedTableResult,
  normalizeTablePagination,
} from "./dashboard-pagination.util";
import {
  loadValorStockLotesFromMovements,
  sumValorStockFromLotes,
} from "./dashboard-valor-stock.util";
import { FinancialMetricsService } from "../../finance/application/services/financial-metrics.service";

type PeriodParams = {
  days?: number;
  period?: string;
  from?: string;
  to?: string;
};

type ExecutiveTableParams = PeriodParams & {
  table: "ultimasVendas" | "alertasCriticos" | "ultimosEventos";
  page?: number;
  pageSize?: number;
  search?: string;
  clienteId?: string;
  estado?: string;
  metodoPagamento?: string;
  sortBy?: string;
  sortDir?: "asc" | "desc";
};

export class ExecutiveDashboardUseCase {
  async execute(params: PeriodParams = {}) {
    const prisma = getPrisma() as any;
    const metricsService = new FinancialMetricsService(prisma);
    const resolved = resolveDashboardPeriod(params);
    const days = resolved.days;
    const now = new Date();
    const todayStart = startOfDay(now);
    const todayEnd = endOfDay(now);
    const chartFrom = resolved.from;
    const periodEnd = resolved.to;
    const periodRange = { from: chartFrom, to: periodEnd };

    const faturaWhere = { ...FATURA_VENDA_WHERE };

    const [
      produtosVendidosAgg,
      clientesAtivosMes,
      contasReceberAgg,
      contasPagarAgg,
      stockAgg,
      produtosCriticos,
      lotesExpirados,
      produtosProximosValidade,
      faturasChart,
      faturasMensais,
      metodosPagamento,
      topProdutos,
      topCategoriasSource,
      ultimasVendas,
      alertasCriticos,
      ultimosEventos,
    ] = await prisma.$transaction([
      prisma.faturaItem.aggregate({
        where: {
          produtoId: { not: null },
          fatura: {
            ...faturaWhere,
            createdAt: { gte: chartFrom, lte: periodEnd },
          },
        },
        _sum: { quantidade: true },
      }),
      prisma.fatura.findMany({
        where: {
          ...faturaWhere,
          createdAt: { gte: chartFrom, lte: periodEnd },
        },
        distinct: ["clienteId"],
        select: { clienteId: true },
      }),
      prisma.contaReceber.aggregate({
        where: { status: { in: ["ABERTA", "PARCIAL"] } },
        _sum: { saldo: true },
      }),
      prisma.contaPagar.aggregate({
        where: { status: { in: ["ABERTA", "PARCIAL"] } },
        _sum: { saldo: true },
      }),
      prisma.stockBalance.aggregate({
        _sum: {
          quantidadeDisponivel: true,
          quantidadeReservada: true,
        },
      }),
      prisma.produto.findMany({
        where: {
          deletedAt: null,
          ativo: true,
        },
        select: {
          estoqueMinimo: true,
          stockBalance: { select: { quantidadeDisponivel: true } },
        },
      }),
      prisma.lote.count({
        where: {
          deletedAt: null,
          ativo: true,
          stockBalance: { quantidadeDisponivel: { gt: 0 } },
          dataValidade: { lt: now },
        },
      }),
      prisma.produto.count({
        where: {
          deletedAt: null,
          ativo: true,
          lotes: {
            some: {
              deletedAt: null,
              ativo: true,
              stockBalance: { quantidadeDisponivel: { gt: 0 } },
              dataValidade: {
                gte: now,
                lte: new Date(now.getTime() + 30 * 86400000),
              },
            },
          },
        },
      }),
      prisma.fatura.findMany({
        where: {
          ...faturaWhere,
          createdAt: { gte: chartFrom, lte: periodEnd },
        },
        select: { createdAt: true, total: true },
        orderBy: { createdAt: "asc" },
      }),
      prisma.fatura.findMany({
        where: {
          ...faturaWhere,
          createdAt: {
            gte: new Date(periodEnd.getFullYear(), periodEnd.getMonth() - 5, 1),
            lte: periodEnd,
          },
        },
        select: { createdAt: true, total: true },
      }),
      prisma.fatura.groupBy({
        by: ["tipoPagamento"],
        where: {
          ...faturaWhere,
          createdAt: { gte: chartFrom, lte: periodEnd },
        },
        _sum: { total: true },
        _count: { _all: true },
      }),
      prisma.faturaItem.groupBy({
        by: ["produtoId"],
        where: {
          produtoId: { not: null },
          fatura: {
            ...faturaWhere,
            createdAt: { gte: chartFrom, lte: periodEnd },
          },
        },
        _sum: { quantidade: true, total: true },
        orderBy: { _sum: { total: "desc" } },
        take: 8,
      }),
      prisma.fatura.findMany({
        where: {
          ...faturaWhere,
          createdAt: { gte: chartFrom, lte: periodEnd },
        },
        select: { total: true, items: { select: { produtoId: true, total: true } } },
        take: 500,
      }),
      prisma.fatura.findMany({
        where: faturaWhere,
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          numero: true,
          total: true,
          estado: true,
          tipoPagamento: true,
          createdAt: true,
          cliente: { select: { id: true, nome: true } },
        },
      }),
      prisma.alertaEstoque.findMany({
        where: { resolvido: false },
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          tipo: true,
          mensagem: true,
          createdAt: true,
          produto: { select: { id: true, nomeComercial: true } },
        },
      }),
      prisma.businessEvent.findMany({
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          type: true,
          entity: true,
          entityId: true,
          createdAt: true,
          user: { select: { id: true, name: true } },
        },
      }),
    ]);

    const todayRange = { from: todayStart, to: todayEnd };
    const previousRange = previousEquivalentPeriod(resolved);

    const [
      receitaHoje,
      metrics,
      numeroFaturasHoje,
      fluxoFinanceiro,
      cashFlow,
      receitaPeriodoAnterior,
    ] = await Promise.all([
      metricsService.calculateRevenue(todayRange),
      metricsService.calculateDreMetrics(periodRange),
      metricsService.calculateSalesCount(todayRange),
      metricsService.getDailyDreFlow(chartFrom, periodEnd, days),
      metricsService.calculateCashFlow(periodRange),
      metricsService.calculateRevenue(previousRange),
    ]);
    const receitaMes = metrics.receita;
    const numeroFaturasMes = metrics.numVendas;
    const ticketMedio = metrics.ticketMedio;
    const lucroBruto = metrics.lucroBruto;
    const lucroLiquido = metrics.lucroLiquido;
    const margem = metrics.margem;
    const crescimentoPercentual = percentGrowth(receitaMes, receitaPeriodoAnterior);
    const saldoAtual = cashFlow.saldoAtual;

    const valorInventarioRows = await loadValorStockLotesFromMovements(prisma, now);
    const valorInventario = sumValorStockFromLotes(valorInventarioRows);

    const produtosCriticosCount = produtosCriticos.filter((row: any) => {
      const disponivel = toNumber(row.stockBalance?.quantidadeDisponivel);
      const minimo = toNumber(row.estoqueMinimo);
      return disponivel > 0 && disponivel <= minimo;
    }).length;

    const receitaDiaria = buildDailySeries(faturasChart, chartFrom, days);
    const receitaMensal = buildMonthlySeries(faturasMensais, 6);
    const evolucaoVendas = receitaDiaria;

    const categoriaTotals = new Map<string, { nome: string; total: number }>();
    const produtoIds = topProdutos
      .map((row: any) => row.produtoId)
      .filter(Boolean);
    const produtosInfo =
      produtoIds.length > 0
        ? await prisma.produto.findMany({
            where: { id: { in: produtoIds } },
            select: {
              id: true,
              nomeComercial: true,
              categoria: { select: { id: true, nome: true } },
            },
          })
        : [];

    const produtoMap = new Map<string, any>(
      produtosInfo.map((p: any) => [p.id.toString(), p]),
    );

    for (const row of topCategoriasSource) {
      for (const item of row.items ?? []) {
        if (!item.produtoId) continue;
        const produto = produtoMap.get(item.produtoId.toString());
        const catId = produto?.categoria?.id?.toString() ?? "sem";
        const catNome = produto?.categoria?.nome ?? "Sem categoria";
        const current = categoriaTotals.get(catId) ?? { nome: catNome, total: 0 };
        current.total += toNumber(item.total);
        categoriaTotals.set(catId, current);
      }
    }

    const topCategoriasList = [...categoriaTotals.values()]
      .sort((a, b) => b.total - a.total)
      .slice(0, 8)
      .map((row) => ({
        categoria: row.nome,
        total: round2(row.total),
      }));

    return {
      kpis: {
        receitaHoje: round2(receitaHoje),
        receitaMes: round2(receitaMes),
        faturamento: round2(receitaMes),
        lucroBruto,
        lucroLiquido,
        margem,
        margemLucro: margem,
        custos: metrics.custos,
        despesas: metrics.despesas,
        totalVendas: round2(receitaMes),
        numVendas: numeroFaturasMes,
        numeroFaturas: numeroFaturasMes,
        numeroFaturasHoje,
        ticketMedio,
        produtosVendidos: round2(toNumber(produtosVendidosAgg._sum.quantidade)),
        clientesAtivos: clientesAtivosMes.length,
        contasReceber: round2(toNumber(contasReceberAgg._sum.saldo)),
        contasPagar: round2(toNumber(contasPagarAgg._sum.saldo)),
        stockTotal: round2(toNumber(stockAgg._sum.quantidadeDisponivel)),
        stockReservado: round2(toNumber(stockAgg._sum.quantidadeReservada)),
        valorInventario: round2(valorInventario),
        produtosCriticos: produtosCriticosCount,
        lotesExpirados,
        produtosProximosValidade,
        saldoAtual,
        crescimento: crescimentoPercentual,
        crescimentoPercentual,
      },
      charts: {
        receitaDiaria,
        receitaMensal,
        evolucaoVendas,
        metodosPagamento: metodosPagamento.map((row: any) => ({
          metodo: row.tipoPagamento,
          total: round2(toNumber(row._sum.total)),
          quantidade: row._count._all ?? 0,
        })),
        topProdutos: topProdutos.map((row: any) => {
          const produto = produtoMap.get(row.produtoId?.toString() ?? "");
          return {
            produtoId: row.produtoId?.toString() ?? null,
            produtoNomeComercial: produto?.nomeComercial ?? "—",
            quantidade: round2(toNumber(row._sum.quantidade)),
            total: round2(toNumber(row._sum.total)),
          };
        }),
        topCategorias: topCategoriasList,
        fluxoFinanceiro,
      },
      tables: {
        ultimasVendas: ultimasVendas.map((row: any) => ({
          id: row.id.toString(),
          numero: row.numero,
          total: round2(toNumber(row.total)),
          estado: row.estado,
          tipoPagamento: row.tipoPagamento,
          clienteNome: row.cliente?.nome ?? "—",
          createdAt: row.createdAt.toISOString(),
        })),
        alertasCriticos: alertasCriticos.map((row: any) => ({
          id: row.id.toString(),
          tipo: row.tipo,
          mensagem: row.mensagem,
          produtoNomeComercial: row.produto?.nomeComercial ?? "—",
          createdAt: row.createdAt.toISOString(),
        })),
        ultimosEventos: ultimosEventos.map((row: any) => ({
          id: row.id.toString(),
          type: row.type,
          entity: row.entity,
          entityId: row.entityId?.toString() ?? null,
          userNome: row.user?.name ?? "—",
          createdAt: row.createdAt.toISOString(),
        })),
      },
      periodo: serializePeriodo(resolved),
    };
  }

  async listTable(params: ExecutiveTableParams) {
    const prisma = getPrisma() as any;
    const { page, pageSize } = normalizeTablePagination(params);
    const resolved = resolveDashboardPeriod(params);
    const search = params.search?.trim();
    const sortDir = params.sortDir === "asc" ? "asc" : "desc";

    switch (params.table) {
      case "ultimasVendas": {
        const where: any = {
          ...FATURA_VENDA_WHERE,
          createdAt: { gte: resolved.from, lte: resolved.to },
        };
        if (params.clienteId) where.clienteId = BigInt(params.clienteId);
        if (params.estado) where.estado = params.estado;
        if (params.metodoPagamento) where.tipoPagamento = params.metodoPagamento;
        if (search) {
          where.OR = [
            { numero: { contains: search, mode: "insensitive" } },
            { cliente: { nome: { contains: search, mode: "insensitive" } } },
          ];
        }
        const orderBy =
          params.sortBy === "total"
            ? { total: sortDir }
            : params.sortBy === "numero"
              ? { numero: sortDir }
              : { createdAt: sortDir };
        const [totalCount, rows] = await prisma.$transaction([
          prisma.fatura.count({ where }),
          prisma.fatura.findMany({
            where,
            orderBy,
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              numero: true,
              total: true,
              estado: true,
              tipoPagamento: true,
              createdAt: true,
              cliente: { select: { nome: true } },
            },
          }),
        ]);
        return buildPagedTableResult({
          table: params.table,
          page,
          pageSize,
          totalCount,
          rows: rows.map((row: any) => ({
            id: row.id.toString(),
            numero: row.numero,
            total: round2(toNumber(row.total)),
            estado: row.estado,
            tipoPagamento: row.tipoPagamento,
            clienteNome: row.cliente?.nome ?? "—",
            createdAt: row.createdAt.toISOString(),
          })),
        });
      }
      case "alertasCriticos": {
        const where: any = {
          resolvido: false,
          createdAt: { gte: resolved.from, lte: resolved.to },
        };
        if (search) {
          where.OR = [
            { mensagem: { contains: search, mode: "insensitive" } },
            { produto: { nomeComercial: { contains: search, mode: "insensitive" } } },
          ];
        }
        const [totalCount, rows] = await prisma.$transaction([
          prisma.alertaEstoque.count({ where }),
          prisma.alertaEstoque.findMany({
            where,
            orderBy: { createdAt: sortDir },
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              tipo: true,
              mensagem: true,
              createdAt: true,
              produto: { select: { nomeComercial: true } },
            },
          }),
        ]);
        return buildPagedTableResult({
          table: params.table,
          page,
          pageSize,
          totalCount,
          rows: rows.map((row: any) => ({
            id: row.id.toString(),
            tipo: row.tipo,
            mensagem: row.mensagem,
            produtoNomeComercial: row.produto?.nomeComercial ?? "—",
            createdAt: row.createdAt.toISOString(),
          })),
        });
      }
      case "ultimosEventos": {
        const where: any = {
          createdAt: { gte: resolved.from, lte: resolved.to },
        };
        if (search) {
          where.OR = [
            { entity: { contains: search, mode: "insensitive" } },
            { type: { contains: search, mode: "insensitive" } },
            { user: { name: { contains: search, mode: "insensitive" } } },
          ];
        }
        const [totalCount, rows] = await prisma.$transaction([
          prisma.businessEvent.count({ where }),
          prisma.businessEvent.findMany({
            where,
            orderBy: { createdAt: sortDir },
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              type: true,
              entity: true,
              entityId: true,
              createdAt: true,
              user: { select: { name: true } },
            },
          }),
        ]);
        return buildPagedTableResult({
          table: params.table,
          page,
          pageSize,
          totalCount,
          rows: rows.map((row: any) => ({
            id: row.id.toString(),
            type: row.type,
            entity: row.entity,
            entityId: row.entityId?.toString() ?? null,
            userNome: row.user?.name ?? "—",
            createdAt: row.createdAt.toISOString(),
          })),
        });
      }
    }
  }
}

function buildDailySeries(
  rows: Array<{ createdAt: Date; total: unknown }>,
  from: Date,
  days: number,
) {
  const buckets = new Map<string, number>();
  for (let i = 0; i < days; i++) {
    const d = new Date(from);
    d.setDate(from.getDate() + i);
    buckets.set(toIsoDate(d), 0);
  }
  for (const row of rows) {
    const key = toIsoDate(new Date(row.createdAt));
    if (!buckets.has(key)) continue;
    buckets.set(key, (buckets.get(key) ?? 0) + toNumber(row.total));
  }
  return [...buckets.entries()].map(([data, total]) => ({
    data,
    total: round2(total),
  }));
}

function buildMonthlySeries(
  rows: Array<{ createdAt: Date; total: unknown }>,
  months: number,
) {
  const now = new Date();
  const buckets = new Map<string, number>();
  for (let i = months - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    buckets.set(key, 0);
  }
  for (const row of rows) {
    const d = new Date(row.createdAt);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    if (!buckets.has(key)) continue;
    buckets.set(key, (buckets.get(key) ?? 0) + toNumber(row.total));
  }
  return [...buckets.entries()].map(([mes, total]) => ({
    mes,
    total: round2(total),
  }));
}

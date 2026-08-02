import { getPrisma } from "../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  FATURA_VENDA_WHERE,
  endOfDay,
  round2,
  startOfDay,
  toNumber,
} from "./dashboard-date.util";
import {
  resolveDashboardPeriod,
  serializePeriodo,
} from "./dashboard-period.util";
import {
  buildPagedTableResult,
  normalizeTablePagination,
} from "./dashboard-pagination.util";
import { FinancialMetricsService } from "../../finance/application/services/financial-metrics.service";
import {
  type DataScope,
  userScopeWhere,
} from "../../shared/data-scope";

type PeriodParams = {
  days?: number;
  period?: string;
  from?: string;
  to?: string;
  scope?: DataScope;
};

type CashierTableParams = PeriodParams & {
  table: "ultimasVendas" | "movimentosCaixa";
  page?: number;
  pageSize?: number;
  search?: string;
  estado?: string;
  metodoPagamento?: string;
  sortBy?: string;
  sortDir?: "asc" | "desc";
};

export class CashierDashboardUseCase {
  async execute(params: PeriodParams = {}) {
    const prisma = getPrisma() as any;
    const metricsService = new FinancialMetricsService(prisma);
    const resolved = resolveDashboardPeriod(params);
    const now = new Date();
    const todayStart = startOfDay(now);
    const todayEnd = endOfDay(now);
    const scopeFilter = params.scope ? userScopeWhere(params.scope) : {};
    const todayRange = {
      from: todayStart,
      to: todayEnd,
      userId: params.scope?.filterUserId ?? null,
    };
    const periodRange = {
      from: resolved.from,
      to: resolved.to,
      userId: params.scope?.filterUserId ?? null,
    };

    const [
      vendasHoje,
      numVendasHoje,
      cashFlowHoje,
      cashFlowPeriodo,
      metodosPagamento,
      ultimasVendas,
      movimentosCaixa,
      sessoesAbertas,
    ] = await Promise.all([
      metricsService.calculateRevenue(todayRange),
      metricsService.calculateSalesCount(todayRange),
      metricsService.calculateCashFlow(todayRange),
      metricsService.calculateCashFlow(periodRange),
      prisma.fatura.groupBy({
        by: ["tipoPagamento"],
        where: {
          ...FATURA_VENDA_WHERE,
          ...scopeFilter,
          createdAt: { gte: todayStart, lte: todayEnd },
        },
        _sum: { total: true },
        _count: { _all: true },
      }),
      prisma.fatura.findMany({
        where: {
          ...FATURA_VENDA_WHERE,
          ...scopeFilter,
          createdAt: { gte: todayStart, lte: todayEnd },
        },
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
      prisma.caixaMovimento.findMany({
        where: {
          deletedAt: null,
          ...scopeFilter,
          createdAt: { gte: todayStart, lte: todayEnd },
        },
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          tipo: true,
          valor: true,
          saldoFinal: true,
          createdAt: true,
          descricao: true,
          caixa: {
            select: {
              id: true,
              terminal: { select: { codigo: true, nome: true } },
            },
          },
        },
      }),
      prisma.caixaSessao.count({
        where: {
          status: "ABERTA",
          deletedAt: null,
          ...scopeFilter,
        },
      }),
    ]);

    const ticketMedio =
      numVendasHoje > 0 ? round2(vendasHoje / numVendasHoje) : 0;
    const caixaAberto = sessoesAbertas > 0;

    return {
      kpis: {
        totalVendasDia: round2(vendasHoje),
        numVendas: numVendasHoje,
        ticketMedio,
        valorEmCaixa: round2(cashFlowHoje.saldoAtual),
        saldoAtual: round2(cashFlowHoje.saldoAtual),
        caixaAberto,
        estadoCaixa: caixaAberto ? "ABERTO" : "FECHADO",
        sessoesAbertas,
        vendas: round2(cashFlowHoje.vendas),
        suprimentos: round2(cashFlowHoje.suprimentos),
        sangrias: round2(cashFlowHoje.sangrias),
        despesasOperacionais: round2(cashFlowHoje.despesasOperacionais),
        comprasEstoque: round2(cashFlowHoje.comprasEstoque),
        estornos: round2(cashFlowHoje.estornos),
        entradas: round2(cashFlowHoje.entradas),
        saidas: round2(cashFlowHoje.saidas),
        fluxoCaixa: round2(cashFlowHoje.fluxoCaixa),
      },
      charts: {
        metodosPagamento: metodosPagamento.map((row: any) => ({
          metodo: row.tipoPagamento ?? "OUTRO",
          total: round2(toNumber(row._sum.total)),
          quantidade: row._count._all ?? 0,
        })),
        resumoMovimento: [
          { tipo: "Vendas", valor: round2(cashFlowHoje.vendas) },
          { tipo: "Suprimentos", valor: round2(cashFlowHoje.suprimentos) },
          { tipo: "Sangrias", valor: round2(cashFlowHoje.sangrias) },
          {
            tipo: "Despesas",
            valor: round2(cashFlowHoje.despesasOperacionais),
          },
          {
            tipo: "Compras estoque",
            valor: round2(cashFlowHoje.comprasEstoque),
          },
          { tipo: "Estornos", valor: round2(cashFlowHoje.estornos) },
        ].filter((row) => row.valor !== 0),
        fluxoPeriodo: {
          vendas: round2(cashFlowPeriodo.vendas),
          entradas: round2(cashFlowPeriodo.entradas),
          saidas: round2(cashFlowPeriodo.saidas),
          saldoAtual: round2(cashFlowPeriodo.saldoAtual),
        },
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
        movimentosCaixa: movimentosCaixa.map((row: any) => ({
          id: row.id.toString(),
          tipo: row.tipo,
          valor: round2(toNumber(row.valor)),
          saldoFinal: round2(toNumber(row.saldoFinal)),
          descricao: row.descricao ?? "—",
          terminal:
            row.caixa?.terminal?.nome ??
            row.caixa?.terminal?.codigo ??
            "—",
          createdAt: row.createdAt.toISOString(),
        })),
      },
      scope: params.scope
        ? { mode: params.scope.mode, filterUserId: params.scope.filterUserId }
        : undefined,
      periodo: serializePeriodo(resolved),
    };
  }

  async listTable(params: CashierTableParams) {
    const prisma = getPrisma() as any;
    const { page, pageSize } = normalizeTablePagination(params);
    const resolved = resolveDashboardPeriod(params);
    const search = params.search?.trim();
    const sortDir = params.sortDir === "asc" ? "asc" : "desc";
    const now = new Date();
    const todayStart = startOfDay(now);
    const todayEnd = endOfDay(now);
    const scopeFilter = params.scope ? userScopeWhere(params.scope) : {};
    // Operação diária: tabelas do caixa focam no dia actual.
    const from = params.from || params.to || params.period || params.days
      ? resolved.from
      : todayStart;
    const to = params.from || params.to || params.period || params.days
      ? resolved.to
      : todayEnd;

    switch (params.table) {
      case "ultimasVendas": {
        const where: any = {
          ...FATURA_VENDA_WHERE,
          ...scopeFilter,
          createdAt: { gte: from, lte: to },
        };
        if (params.estado) where.estado = params.estado;
        if (params.metodoPagamento) where.tipoPagamento = params.metodoPagamento;
        if (search) {
          where.OR = [
            { numero: { contains: search } },
            { cliente: { nome: { contains: search } } },
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
        const hasMore = rows.length > pageSize;
        const pageRows = hasMore ? rows.slice(0, pageSize) : rows;
        return buildPagedTableResult({
          page,
          pageSize,
          totalCount,
          hasMore,
          rows: pageRows.map((row: any) => ({
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
      case "movimentosCaixa": {
        const where: any = {
          deletedAt: null,
          ...scopeFilter,
          createdAt: { gte: from, lte: to },
        };
        if (params.estado) where.tipo = params.estado;
        if (search) {
          where.OR = [
            { descricao: { contains: search } },
            { tipo: { contains: search } },
          ];
        }
        const orderBy =
          params.sortBy === "valor"
            ? { valor: sortDir }
            : { createdAt: sortDir };
        const [totalCount, rows] = await prisma.$transaction([
          prisma.caixaMovimento.count({ where }),
          prisma.caixaMovimento.findMany({
            where,
            orderBy,
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              tipo: true,
              valor: true,
              saldoFinal: true,
              descricao: true,
              createdAt: true,
              caixa: {
                select: {
                  terminal: { select: { codigo: true, nome: true } },
                },
              },
            },
          }),
        ]);
        const hasMore = rows.length > pageSize;
        const pageRows = hasMore ? rows.slice(0, pageSize) : rows;
        return buildPagedTableResult({
          page,
          pageSize,
          totalCount,
          hasMore,
          rows: pageRows.map((row: any) => ({
            id: row.id.toString(),
            tipo: row.tipo,
            valor: round2(toNumber(row.valor)),
            saldoFinal: round2(toNumber(row.saldoFinal)),
            descricao: row.descricao ?? "—",
            terminal:
              row.caixa?.terminal?.nome ??
              row.caixa?.terminal?.codigo ??
              "—",
            createdAt: row.createdAt.toISOString(),
          })),
        });
      }
      default:
        throw new Error(`Tabela inválida: ${(params as any).table}`);
    }
  }
}

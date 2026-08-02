import { getPrisma } from "../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  FATURA_VENDA_WHERE,
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
import { ListContasPagarUseCase } from "./list-contas-pagar.use-case";
import { ListContasReceberUseCase } from "./list-contas-receber.use-case";
import { ListFinancialMovementsUseCase } from "./list-financial-movements.use-case";
import type { DataScope } from "../../shared/data-scope";
import { userScopeWhere } from "../../shared/data-scope";

type PeriodParams = {
  days?: number;
  period?: string;
  from?: string;
  to?: string;
  scope?: DataScope;
};
type FinanceTableParams = PeriodParams & {
  table:
    | "ultimosPagamentos"
    | "ultimasReceitas"
    | "ultimasDespesas"
    | "contasVencidas"
    | "fluxoCaixa"
    | "contasReceber"
    | "contasPagar";
  page?: number;
  pageSize?: number;
  search?: string;
  clienteId?: string;
  estado?: string;
  metodoPagamento?: string;
  sortBy?: string;
  sortDir?: "asc" | "desc";
};

export class FinanceDashboardUseCase {
  async execute(params: PeriodParams = {}) {
    const prisma = getPrisma() as any;
    const metricsService = new FinancialMetricsService(prisma);
    const resolved = resolveDashboardPeriod(params);
    const days = resolved.days;
    const now = new Date();
    const chartFrom = resolved.from;
    const periodEnd = resolved.to;
    const metricsRange = {
      from: chartFrom,
      to: periodEnd,
      userId: params.scope?.filterUserId ?? null,
    };
    const scopeFilter = params.scope ? userScopeWhere(params.scope) : {};
    const [
      dreMetrics,
      cashFlowMetrics,
      dreFlowDaily,
      dreFlowMonthly,
      contasReceberAgg,
      contasPagarAgg,
      recebimentosPendentes,
      pagamentosPendentes,
      pagamentosRecentes,
      receitasRecentes,
      despesasRecentes,
      contasVencidas,
      metodosPagamento,
      despesasPorCategoriaRows,
    ] = await Promise.all([
      metricsService.calculateDreMetrics(metricsRange),
      metricsService.calculateCashFlow(metricsRange),
      metricsService.getDailyDreFlow(
        chartFrom,
        periodEnd,
        days,
        undefined,
        params.scope?.filterUserId,
      ),
      metricsService.getMonthlyDreFlow(
        periodEnd,
        6,
        undefined,
        params.scope?.filterUserId,
      ),
      prisma.contaReceber.aggregate({
        where: { status: { in: ["ABERTA", "PARCIAL"] } },
        _sum: { saldo: true },
      }),
      prisma.contaPagar.aggregate({
        where: { status: { in: ["ABERTA", "PARCIAL"] } },
        _sum: { saldo: true },
      }),
      prisma.contaReceber.count({
        where: { status: { in: ["ABERTA", "PARCIAL"] } },
      }),
      prisma.contaPagar.count({
        where: { status: { in: ["ABERTA", "PARCIAL"] } },
      }),
      prisma.pagamento.findMany({
        where: {
          deletedAt: null,
          ...(params.scope?.filterUserId
            ? { fatura: { userId: BigInt(params.scope.filterUserId) } }
            : {}),
        },
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          valor: true,
          metodo: true,
          status: true,
          createdAt: true,
          fatura: { select: { numero: true } },
        },
      }),
      prisma.financialMovement.findMany({
        where: {
          deletedAt: null,
          type: { in: ["SALE", "DEBT_PAYMENT"] },
          ...scopeFilter,
        },
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          amount: true,
          type: true,
          reference: true,
          createdAt: true,
        },
      }),
      prisma.financialMovement.findMany({
        where: {
          deletedAt: null,
          type: { in: ["EXPENSE", "PURCHASE", "REFUND"] },
          ...scopeFilter,
        },
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          amount: true,
          type: true,
          reference: true,
          createdAt: true,
        },
      }),
      prisma.contaReceber.findMany({
        where: {
          status: { in: ["ABERTA", "PARCIAL"] },
          vencimento: { lt: now },
        },
        orderBy: { vencimento: "asc" },
        take: 10,
        select: {
          id: true,
          valor: true,
          saldo: true,
          vencimento: true,
          cliente: { select: { nome: true } },
        },
      }),
      prisma.fatura.groupBy({
        by: ["tipoPagamento"],
        where: {
          ...FATURA_VENDA_WHERE,
          ...scopeFilter,
          createdAt: { gte: chartFrom, lte: periodEnd },
        },
        _sum: { total: true },
        _count: { _all: true },
      }),
      // DESPESA_OPERACIONAL (null categoria → OUTRO no mapeamento)
      prisma.caixaMovimento.groupBy({
        by: ["categoria"],
        where: {
          deletedAt: null,
          tipo: "DESPESA_OPERACIONAL",
          ...scopeFilter,
          createdAt: { gte: chartFrom, lte: periodEnd },
        },
        _sum: { valor: true },
      }),
    ]);

    const {
      receita,
      faturamento,
      custos,
      lucroBruto,
      lucroLiquido,
      margem,
      ticketMedio,
      numVendas,
      despesas,
    } = dreMetrics;
    const {
      saldoInicial,
      vendas,
      suprimentos,
      despesas: despesasCaixa,
      despesasOperacionais,
      comprasEstoque,
      sangrias,
      estornos,
      saldoFinal,
      saldoAtual,
      fluxoCaixa,
      entradas,
      saidas,
    } = cashFlowMetrics;

    const despesasPorCategoria = despesasPorCategoriaRows
      .map((row: any) => {
        const valor = round2(toNumber(row._sum?.valor));
        return {
          categoria: (row.categoria as string | null) ?? "OUTRO",
          valor,
          total: valor,
        };
      })
      .filter((row: { total: number }) => row.total > 0)
      .sort((a: { total: number }, b: { total: number }) => b.total - a.total);

    const recebimentosPorCategoria = metodosPagamento.map((row: any) => ({
      categoria: row.tipoPagamento ?? "OUTRO",
      total: round2(toNumber(row._sum.total)),
      valor: round2(toNumber(row._sum.total)),
    }));

    return {
      kpis: {
        // Operação de caixa
        saldoInicial,
        vendas,
        suprimentos,
        despesasCaixa,
        despesasOperacionais,
        comprasEstoque,
        sangrias,
        estornos,
        saldoFinal,
        saldoAtual,
        // Desempenho comercial (não entra no saldo como receita de suprimento)
        receita,
        faturamento,
        numVendas,
        ticketMedio,
        custos,
        cmv: custos,
        lucroBruto,
        lucroLiquido,
        margem,
        margemLucro: margem,
        lucro: lucroLiquido,
        despesas,
        fluxoCaixa,
        entradas,
        saidas,
        contasReceber: round2(toNumber(contasReceberAgg._sum.saldo)),
        contasPagar: round2(toNumber(contasPagarAgg._sum.saldo)),
        recebimentosPendentes,
        pagamentosPendentes,
      },
      charts: {
        fluxoDiario: dreFlowDaily,
        fluxoMensal: dreFlowMonthly,
        receitasDespesas: dreFlowDaily,
        evolucaoFinanceira: dreFlowMonthly,
        metodosPagamento: metodosPagamento.map((row: any) => ({
          metodo: row.tipoPagamento,
          total: round2(toNumber(row._sum.total)),
          quantidade: row._count._all ?? 0,
        })),
        despesasPorCategoria,
        recebimentosPorCategoria,
      },
      tables: {
        ultimosPagamentos: pagamentosRecentes.map((row: any) => ({
          id: row.id.toString(),
          valor: round2(toNumber(row.valor)),
          metodo: row.metodo,
          status: row.status,
          faturaNumero: row.fatura?.numero ?? "—",
          createdAt: row.createdAt.toISOString(),
        })),
        ultimasReceitas: receitasRecentes.map((row: any) => ({
          id: row.id.toString(),
          valor: round2(toNumber(row.amount)),
          tipo: row.type,
          referencia: row.reference ?? "—",
          createdAt: row.createdAt.toISOString(),
        })),
        ultimasDespesas: despesasRecentes.map((row: any) => ({
          id: row.id.toString(),
          valor: round2(toNumber(row.amount)),
          tipo: row.type,
          referencia: row.reference ?? "—",
          createdAt: row.createdAt.toISOString(),
        })),
        contasVencidas: contasVencidas.map((row: any) => ({
          id: row.id.toString(),
          clienteNome: row.cliente?.nome ?? "—",
          valor: round2(toNumber(row.valor)),
          saldo: round2(toNumber(row.saldo)),
          vencimento: row.vencimento?.toISOString() ?? null,
        })),
      },
      periodo: serializePeriodo(resolved),
    };
  }

  async listTable(params: FinanceTableParams) {
    const prisma = getPrisma() as any;
    const { page, pageSize } = normalizeTablePagination(params);
    const resolved = resolveDashboardPeriod(params);
    const search = params.search?.trim();
    const sortDir = params.sortDir === "asc" ? "asc" : "desc";
    const now = new Date();
    const scopeFilter = params.scope ? userScopeWhere(params.scope) : {};
    const pagamentoScope = params.scope?.filterUserId
      ? { fatura: { userId: BigInt(params.scope.filterUserId) } }
      : {};

    switch (params.table) {
      case "ultimosPagamentos": {
        const where: any = {
          deletedAt: null,
          createdAt: { gte: resolved.from, lte: resolved.to },
          ...pagamentoScope,
        };
        if (params.metodoPagamento) where.metodo = params.metodoPagamento;
        if (params.estado) where.status = params.estado;
        if (search) {
          where.OR = [
            { metodo: { contains: search, mode: "insensitive" } },
            { fatura: { numero: { contains: search, mode: "insensitive" } } },
          ];
        }
        const [totalCount, rows] = await prisma.$transaction([
          prisma.pagamento.count({ where }),
          prisma.pagamento.findMany({
            where,
            orderBy: { createdAt: sortDir },
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              valor: true,
              metodo: true,
              status: true,
              createdAt: true,
              fatura: { select: { numero: true } },
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
            valor: round2(toNumber(row.valor)),
            metodo: row.metodo,
            status: row.status,
            faturaNumero: row.fatura?.numero ?? "—",
            createdAt: row.createdAt.toISOString(),
          })),
        });
      }
      case "ultimasReceitas": {
        const where: any = {
          deletedAt: null,
          type: { in: ["SALE", "DEBT_PAYMENT"] },
          createdAt: { gte: resolved.from, lte: resolved.to },
          ...scopeFilter,
        };
        if (search) {
          where.OR = [
            { reference: { contains: search, mode: "insensitive" } },
            { type: { contains: search, mode: "insensitive" } },
          ];
        }
        const [totalCount, rows] = await prisma.$transaction([
          prisma.financialMovement.count({ where }),
          prisma.financialMovement.findMany({
            where,
            orderBy: { createdAt: sortDir },
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              amount: true,
              type: true,
              reference: true,
              createdAt: true,
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
            valor: round2(toNumber(row.amount)),
            tipo: row.type,
            referencia: row.reference ?? "—",
            createdAt: row.createdAt.toISOString(),
          })),
        });
      }
      case "ultimasDespesas": {
        const where: any = {
          deletedAt: null,
          type: { in: ["EXPENSE", "PURCHASE", "REFUND"] },
          createdAt: { gte: resolved.from, lte: resolved.to },
          ...scopeFilter,
        };
        if (search) {
          where.OR = [
            { reference: { contains: search, mode: "insensitive" } },
            { type: { contains: search, mode: "insensitive" } },
          ];
        }
        const [totalCount, rows] = await prisma.$transaction([
          prisma.financialMovement.count({ where }),
          prisma.financialMovement.findMany({
            where,
            orderBy: { createdAt: sortDir },
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              amount: true,
              type: true,
              reference: true,
              createdAt: true,
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
            valor: round2(toNumber(row.amount)),
            tipo: row.type,
            referencia: row.reference ?? "—",
            createdAt: row.createdAt.toISOString(),
          })),
        });
      }
      case "contasVencidas": {
        const where: any = {
          status: { in: ["ABERTA", "PARCIAL"] },
          vencimento: { gte: resolved.from, lt: now },
        };
        if (params.clienteId) where.clienteId = BigInt(params.clienteId);
        if (search) {
          where.cliente = { nome: { contains: search, mode: "insensitive" } };
        }
        const [totalCount, rows] = await prisma.$transaction([
          prisma.contaReceber.count({ where }),
          prisma.contaReceber.findMany({
            where,
            orderBy: { vencimento: sortDir },
            skip: (page - 1) * pageSize,
            take: pageSize + 1,
            select: {
              id: true,
              valor: true,
              saldo: true,
              vencimento: true,
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
            clienteNome: row.cliente?.nome ?? "—",
            valor: round2(toNumber(row.valor)),
            saldo: round2(toNumber(row.saldo)),
            vencimento: row.vencimento?.toISOString() ?? null,
          })),
        });
      }
      case "fluxoCaixa": {
        const listUseCase = new ListFinancialMovementsUseCase();
        const result = await listUseCase.execute({
          ...params,
          search,
          page,
          pageSize,
          sortDir,
        });
        return {
          table: params.table,
          items: result.items,
          page: result.page,
          pageSize: result.pageSize,
          hasMore: result.hasMore,
          hasPrevious: result.hasPrevious,
          totalCount: result.totalCount,
          totalPages: result.totalPages,
        };
      }
      case "contasReceber": {
        const listUseCase = new ListContasReceberUseCase();
        const result = await listUseCase.execute({
          status: params.estado,
          clienteId: params.clienteId,
          search,
          page,
          pageSize,
          sortDir,
        });
        return {
          table: params.table,
          items: result.items,
          page: result.page,
          pageSize: result.pageSize,
          hasMore: result.hasMore,
          hasPrevious: result.hasPrevious,
          totalCount: result.totalCount,
          totalPages: result.totalPages,
        };
      }
      case "contasPagar": {
        const listUseCase = new ListContasPagarUseCase();
        const result = await listUseCase.execute({
          status: params.estado,
          fornecedorId: params.fornecedorId,
          search,
          page,
          pageSize,
          sortDir,
        });
        return {
          table: params.table,
          items: result.items,
          page: result.page,
          pageSize: result.pageSize,
          hasMore: result.hasMore,
          hasPrevious: result.hasPrevious,
          totalCount: result.totalCount,
          totalPages: result.totalPages,
        };
      }
    }
  }
}

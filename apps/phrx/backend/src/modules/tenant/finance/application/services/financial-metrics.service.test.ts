import { describe, expect, test } from "bun:test";
import { FinancialMetricsService } from "./financial-metrics.service";

describe("FinancialMetricsService", () => {
  test("calculateDreMetrics centralizes revenue, CMV, net profit and margin", async () => {
    const service = new FinancialMetricsService({
      fatura: {
        aggregate: async () => ({
          _sum: { total: 1000 },
        }),
        count: async () => 4,
      },
      faturaItem: {
        findMany: async () => [
          { quantidade: 2, custoUnitario: 100 },
          { quantidade: 3, custoUnitario: 50 },
        ],
      },
      financialMovement: {
        aggregate: async ({ where }: any) => {
          expect(where.type).toBe("EXPENSE");
          return { _sum: { amount: 120 } };
        },
      },
    });

    const metrics = await service.calculateDreMetrics({
      from: new Date("2026-07-01T00:00:00.000Z"),
      to: new Date("2026-07-31T23:59:59.999Z"),
    });

    expect(metrics.receita).toBe(1000);
    expect(metrics.faturamento).toBe(1000);
    expect(metrics.custos).toBe(350);
    expect(metrics.lucroBruto).toBe(650);
    expect(metrics.despesas).toBe(120);
    expect(metrics.lucroLiquido).toBe(530);
    expect(metrics.margem).toBe(53);
    expect(metrics.margemLucro).toBe(53);
    expect(metrics.ticketMedio).toBe(250);
    expect(metrics.numVendas).toBe(4);
  });

  test("calculateOperationalExpenses excludes stock purchases from DRE", async () => {
    let receivedWhere: any;
    const service = new FinancialMetricsService({
      financialMovement: {
        aggregate: async (args: any) => {
          receivedWhere = args.where;
          return { _sum: { amount: 80 } };
        },
      },
    });

    const total = await service.calculateOperationalExpenses({
      from: new Date("2026-07-01T00:00:00.000Z"),
      to: new Date("2026-07-31T23:59:59.999Z"),
    });

    expect(total).toBe(80);
    expect(receivedWhere.type).toBe("EXPENSE");
  });

  test("calculateCashFlow separates caixa operation from DRE", async () => {
    const service = new FinancialMetricsService({
      caixaMovimento: {
        aggregate: async ({ where }: any) => {
          switch (where.tipo) {
            case "VENDA":
              return { _sum: { valor: 500 } };
            case "DESPESA_OPERACIONAL":
              return { _sum: { valor: 70 } };
            case "COMPRA_ESTOQUE":
              return { _sum: { valor: 20 } };
            case "SUPRIMENTO":
              return { _sum: { valor: 40 } };
            case "SANGRIA":
              return { _sum: { valor: 30 } };
            case "ESTORNO":
              return { _sum: { valor: 10 } };
            default:
              return { _sum: { valor: 0 } };
          }
        },
        findMany: async () => [{ saldoAnterior: 120, saldoFinal: 130 }],
      },
      cashBalance: {
        aggregate: async () => ({
          _sum: { saldoTotal: 550 },
        }),
      },
      $transaction: async (operations: Array<Promise<any>>) => Promise.all(operations),
    });

    const metrics = await service.calculateCashFlow({
      from: new Date("2026-07-01T00:00:00.000Z"),
      to: new Date("2026-07-31T23:59:59.999Z"),
    });

    expect(metrics.vendas).toBe(500);
    expect(metrics.despesasOperacionais).toBe(70);
    expect(metrics.comprasEstoque).toBe(20);
    expect(metrics.despesas).toBe(90);
    expect(metrics.suprimentos).toBe(40);
    expect(metrics.sangrias).toBe(30);
    expect(metrics.estornos).toBe(10);
    expect(metrics.estornosSigned).toBe(10);
    expect(metrics.saldoInicial).toBe(120);
    expect(metrics.saldoFinal).toBe(550);
    expect(metrics.saldoAtual).toBe(550);
    expect(metrics.entradas).toBe(550);
    expect(metrics.saidas).toBe(120);
    expect(metrics.fluxoCaixa).toBe(430);
  });

  test("getDailyDreFlow uses faturas for receitas and EXPENSE for despesas", async () => {
    const service = new FinancialMetricsService({
      fatura: {
        findMany: async () => [
          { createdAt: new Date("2026-07-01T10:00:00.000Z"), total: 100 },
          { createdAt: new Date("2026-07-01T15:00:00.000Z"), total: 50 },
          { createdAt: new Date("2026-07-02T10:00:00.000Z"), total: 80 },
        ],
      },
      financialMovement: {
        findMany: async ({ where }: any) => {
          expect(where.type).toBe("EXPENSE");
          return [{ createdAt: new Date("2026-07-01T12:00:00.000Z"), amount: 20 }];
        },
      },
    });

    const series = await service.getDailyDreFlow(
      new Date("2026-07-01T00:00:00.000Z"),
      new Date("2026-07-02T23:59:59.999Z"),
      2,
    );

    expect(series).toEqual([
      { data: "2026-07-01", receitas: 150, despesas: 20, saldo: 130 },
      { data: "2026-07-02", receitas: 80, despesas: 0, saldo: 80 },
    ]);
  });
});

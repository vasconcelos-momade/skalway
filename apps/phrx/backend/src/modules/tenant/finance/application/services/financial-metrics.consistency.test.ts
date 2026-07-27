import { describe, expect, test } from "bun:test";
import { FinancialMetricsService } from "./financial-metrics.service";

function createSharedPrismaMock() {
  return {
    fatura: {
      aggregate: async () => ({ _sum: { total: 1000 } }),
      count: async () => 4,
      findMany: async () => [
        { createdAt: new Date("2026-07-01T10:00:00.000Z"), total: 600 },
        { createdAt: new Date("2026-07-02T10:00:00.000Z"), total: 400 },
      ],
    },
    faturaItem: {
      findMany: async () => [{ quantidade: 2, custoUnitario: 100 }],
    },
    financialMovement: {
      aggregate: async () => ({ _sum: { amount: 120 } }),
      findMany: async () => [],
    },
    caixaMovimento: {
      aggregate: async () => ({ _sum: { valor: 0 } }),
      findMany: async () => [],
    },
    cashBalance: {
      aggregate: async () => ({ _sum: { saldoTotal: 0 } }),
    },
    $transaction: async (operations: Array<Promise<unknown>>) => Promise.all(operations),
  };
}

describe("FinancialMetricsService consistency", () => {
  test("calculateDreMetrics returns identical results for repeated calls", async () => {
    const prisma = createSharedPrismaMock();
    const service = new FinancialMetricsService(prisma);
    const range = {
      from: new Date("2026-07-01T00:00:00.000Z"),
      to: new Date("2026-07-31T23:59:59.999Z"),
    };

    const [first, second] = await Promise.all([
      service.calculateDreMetrics(range),
      service.calculateDreMetrics(range),
    ]);

    expect(first).toEqual(second);
    expect(first.receita).toBe(second.faturamento);
    expect(first.lucroLiquido).toBe(first.lucroBruto - first.despesas);
  });

  test("calculateNetProfit always derives from gross profit minus operational expenses", async () => {
    const service = new FinancialMetricsService(createSharedPrismaMock());
    const range = {
      from: new Date("2026-07-01T00:00:00.000Z"),
      to: new Date("2026-07-31T23:59:59.999Z"),
    };

    const [gross, net, expenses] = await Promise.all([
      service.calculateGrossProfit(range),
      service.calculateNetProfit(range),
      service.calculateOperationalExpenses(range),
    ]);

    expect(net).toBe(gross - expenses);
  });
});

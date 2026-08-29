import { describe, expect, test } from "bun:test";

import {
  CONSUMPTION_PERIOD_DAYS,
  DEFAULT_COVERAGE_DAYS,
  buildAutomaticPurchaseSuggestionMetrics,
  calculateConsumoMedioDiario,
  calculateQuantidadeSugerida,
  canApprovePurchaseSuggestionQuantity,
  resolvePurchaseSuggestionPeriod,
  roundSuggestionInteger,
  sumSaidasFromMovements,
  syncPurchaseSuggestionAfterStockChange,
} from "./purchase-suggestion.service";

describe("purchase-suggestion.service", () => {
  test("sumSaidasFromMovements soma saídas absolutas como inteiro", () => {
    expect(
      sumSaidasFromMovements([
        { quantidade: 4 },
        { quantidade: -3.5 },
        { quantidade: 2 },
      ]),
    ).toBe(10);
  });

  test("produto sem saídas resulta em consumo e quantidade baseados em zero", () => {
    const metrics = buildAutomaticPurchaseSuggestionMetrics({
      estoqueAtual: 5,
      estoqueMinimo: 10,
      totalSaidasPeriodo: 0,
    });

    expect(metrics.totalSaidasPeriodo).toBe(0);
    expect(metrics.consumoMedioDiario).toBe(0);
    expect(metrics.quantidadeSugerida).toBe(5);
  });

  test("estoque atual abaixo do mínimo com saídas no período de 30 dias", () => {
    const metrics = buildAutomaticPurchaseSuggestionMetrics({
      estoqueAtual: 5,
      estoqueMinimo: 10,
      totalSaidasPeriodo: 60,
      diasDoPeriodo: CONSUMPTION_PERIOD_DAYS,
      diasReposicao: DEFAULT_COVERAGE_DAYS,
    });

    expect(metrics.totalSaidasPeriodo).toBe(60);
    expect(metrics.consumoMedioDiario).toBe(2);
    expect(metrics.quantidadeSugerida).toBe(65);
  });

  test("estoque atual acima do mínimo reduz a quantidade sugerida", () => {
    const quantidadeSugerida = calculateQuantidadeSugerida({
      estoqueAtual: 20,
      estoqueMinimo: 10,
      totalSaidasPeriodo: 60,
    });

    expect(quantidadeSugerida).toBe(50);
  });

  test("produto com várias saídas acumula o total do período", () => {
    const total = sumSaidasFromMovements([
      { quantidade: -12 },
      { quantidade: -8 },
      { quantidade: -5.4 },
    ]);

    expect(total).toBe(25);
  });

  test("período padrão de 30 dias é exposto no metadata", () => {
    const period = resolvePurchaseSuggestionPeriod({
      referenceDate: new Date("2026-08-28T12:00:00"),
    });

    expect(period.diasDoPeriodo).toBe(30);
    expect(period.coberturaDias).toBe(30);
    expect(period.periodoLabel).toMatch(/\d{2}\/\d{2}\/\d{4} - \d{2}\/\d{2}\/\d{4}/);
  });

  test("resultado decimal é arredondado para inteiro", () => {
    const quantidadeSugerida = calculateQuantidadeSugerida({
      estoqueAtual: 5,
      estoqueMinimo: 10,
      totalSaidasPeriodo: 10,
      diasDoPeriodo: 30,
      diasReposicao: 30,
    });

    expect(calculateConsumoMedioDiario(10, 30)).toBe(0.33);
    expect(quantidadeSugerida).toBe(15);
    expect(roundSuggestionInteger(14.6)).toBe(15);
  });

  test("quantidade sugerida nunca é negativa", () => {
    const quantidadeSugerida = calculateQuantidadeSugerida({
      estoqueAtual: 100,
      estoqueMinimo: 10,
      totalSaidasPeriodo: 5,
    });

    expect(quantidadeSugerida).toBe(0);
  });

  test("novas saídas alteram totalSaidasPeriodo e quantidadeSugerida", () => {
    const antes = buildAutomaticPurchaseSuggestionMetrics({
      estoqueAtual: 5,
      estoqueMinimo: 10,
      totalSaidasPeriodo: 30,
    });
    const depois = buildAutomaticPurchaseSuggestionMetrics({
      estoqueAtual: 5,
      estoqueMinimo: 10,
      totalSaidasPeriodo: 90,
    });

    expect(depois.totalSaidasPeriodo).toBeGreaterThan(antes.totalSaidasPeriodo);
    expect(depois.quantidadeSugerida).toBeGreaterThan(antes.quantidadeSugerida);
  });

  test("roles autorizados podem aprovar quantidade de compra", () => {
    for (const role of ["GERENTE", "DIRETOR_TECNICO", "ADMIN"] as const) {
      expect(canApprovePurchaseSuggestionQuantity(role)).toBe(true);
    }
    expect(canApprovePurchaseSuggestionQuantity("CAIXA")).toBe(false);
    expect(canApprovePurchaseSuggestionQuantity("FARMACEUTICO")).toBe(false);
  });

  test("sync recalcula métricas sem alterar quantidadeAprovada", async () => {
    const produtoId = 42n;
    const upsertCalls: Array<Record<string, unknown>> = [];
    const movements = [{ quantidade: -20 }, { quantidade: -40 }];

    const tx = {
      produto: {
        findUnique: async () => ({
          id: produtoId,
          estoqueMinimo: 10,
          ativo: true,
          deletedAt: null,
          stockBalance: { quantidadeDisponivel: 5 },
          fornecedores: [{ fornecedorPrincipal: true, fornecedorId: 7n }],
        }),
      },
      purchaseSuggestion: {
        findUnique: async () => ({
          id: 1n,
          origem: "MANUAL" as const,
          quantidadeSugerida: 12,
          quantidadeAprovada: 25,
          supplierId: 99n,
        }),
        upsert: async (args: {
          where: { produtoId: bigint };
          create: Record<string, unknown>;
          update: Record<string, unknown>;
        }) => {
          upsertCalls.push(args.update);
          return args;
        },
        delete: async () => undefined,
        deleteMany: async () => undefined,
      },
      estoqueMovimento: {
        findFirst: async () => ({ id: 1n }),
        findMany: async () => movements,
      },
    };

    await syncPurchaseSuggestionAfterStockChange(tx, produtoId, 5);

    expect(upsertCalls).toHaveLength(1);
    expect(upsertCalls[0]?.totalSaidasPeriodo).toBe(60);
    expect(upsertCalls[0]?.quantidadeSugerida).toBe(65);
    expect(upsertCalls[0]).not.toHaveProperty("quantidadeAprovada");
  });
});

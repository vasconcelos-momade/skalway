import { collectAllPages } from "../helpers/report-pagination.helper";
import { formatCurrency, toText } from "../helpers/report-export.helper";
import {
  formatProductDisplayLabel,
  formatSuggestionInteger,
  resolvePurchaseSuggestionPeriod,
} from "../../../stock/domain/purchase-suggestion.service";
import {
  type ModuleReportDefinition,
  type ReportDataProvider,
  type ReportProviderContext,
  type ReportImportantNote,
} from "../types/report.types";
import { REPORT_KEYS, type ReportKey } from "../constants/report-keys";
import { PurchaseSuggestionsUseCase } from "../../../stock/application/use-cases/purchases/purchase-suggestions.use-case";
import { buildStockReportDefinition } from "./helpers/stock-report.builder";

const REPORT_COLUMNS = [
  "#",
  "Produto",
  "Stock atual",
  "Stock mínimo",
  "Saídas",
  "QTD sugerida",
  "QTD. aprovada",
] as const;

function parseSuggestionFilters(url: URL) {
  return {
    q: url.searchParams.get("q") ?? undefined,
    dataInicio: url.searchParams.get("dataInicio") ?? undefined,
    dataFim: url.searchParams.get("dataFim") ?? undefined,
    origem: (url.searchParams.get("origem") as "AUTOMATICA" | "MANUAL" | "TODAS") ?? undefined,
    sortBy: url.searchParams.get("sortBy") ?? undefined,
    sortOrder: (url.searchParams.get("sortOrder") as "asc" | "desc") ?? undefined,
    supplierId: url.searchParams.get("supplierId") ?? undefined,
  };
}

function mapSuggestionRow(item: Record<string, unknown>, rowNumber: number) {
  const produtoLabel =
    typeof item.produtoDisplayLabel === "string" && item.produtoDisplayLabel.trim()
      ? item.produtoDisplayLabel
      : formatProductDisplayLabel({
          nomeComercial: toText(item.produtoNome, ""),
          dosagem: typeof item.produtoDosagem === "string" ? item.produtoDosagem : null,
          forma: typeof item.produtoForma === "string" ? item.produtoForma : null,
        });

  return [
    String(rowNumber),
    produtoLabel,
    toText(item.estoqueAtual, "0"),
    toText(item.estoqueMinimo, "0"),
    formatSuggestionInteger(item.totalSaidasPeriodo),
    formatSuggestionInteger(item.quantidadeSugerida),
    formatSuggestionInteger(item.quantidadeAprovada),
  ];
}

const PURCHASE_SUGGESTIONS_IMPORTANT_NOTE: ReportImportantNote = {
  title: "NOTA IMPORTANTE — UNIDADE DE COMPRA E PRAZO DE VALIDADE",
  blocks: [
    {
      heading: "1. Unidade de compra:",
      intro:
        "As quantidades sugeridas/aprovadas devem ser interpretadas de acordo com a unidade de apresentação e aquisição do produto:",
      items: [
        "Suspensões, xaropes e injetáveis (Inj.): frascos;",
        "Pomadas e cremes: tubos/bisnagas;",
        "Cápsulas e comprimidos: carteiras/blisters, e não caixas.",
      ],
    },
    {
      heading: "2. Prazo de Validade (PV):",
      intro:
        "Antes de efetuar a compra, verificar obrigatoriamente o prazo de validade dos lotes disponíveis. Evitar a aquisição de produtos com PV muito curto, principalmente quando o prazo restante não for compatível com o consumo previsto, de modo a reduzir o risco de vencimento, perdas e problemas no controlo sanitário.",
    },
  ],
};

export class PurchaseSuggestionsReportProvider implements ReportDataProvider {
  readonly reportKey: ReportKey = REPORT_KEYS.PURCHASE_SUGGESTIONS;

  private readonly listUseCase = new PurchaseSuggestionsUseCase();

  async build(context: ReportProviderContext): Promise<ModuleReportDefinition> {
    const filters = parseSuggestionFilters(context.url);

    const firstPage = await this.listUseCase.execute({
      ...filters,
      page: 1,
      pageSize: 100,
    });

    const grouped = await this.loadAllGrouped(filters);
    const dashboard = firstPage.dashboard;
    const period = resolvePurchaseSuggestionPeriod(
      filters.dataInicio && filters.dataFim
        ? { dataInicio: filters.dataInicio, dataFim: filters.dataFim }
        : undefined,
    );
    let rowNumber = 0;

    return {
      ...buildStockReportDefinition({
      fileBaseName: "sugestao-compras",
      reportName: "Sugestão de Compras",
      title: "Sugestão de Compras",
      subtitle: "Lista consolidada agrupada por fornecedor principal",
      reportCode: "Sugestão de Compras",
      periodLabel: period.periodoLabel,
      filters: {
        Pesquisa: filters.q ?? "-",
        Período: period.periodoLabel,
      },
      kpis: {
        Produtos: dashboard.produtosSugeridos,
        "Sem stock": dashboard.produtosSemStock,
        "Qtd. total sugerida": dashboard.quantidadeTotalSugerida,
        Fornecedores: dashboard.fornecedoresEnvolvidos,
        "Valor estimado": formatCurrency(dashboard.valorEstimadoCompra),
      },
      tables: grouped.map((group) => ({
        title: group.fornecedorNome,
        columns: [...REPORT_COLUMNS],
        rows: group.items.map((item) => {
          rowNumber += 1;
          return mapSuggestionRow(item as Record<string, unknown>, rowNumber);
        }),
      })),
      }),
      importantNote: PURCHASE_SUGGESTIONS_IMPORTANT_NOTE,
    };
  }

  /** Carrega todas as páginas e reagrupa por fornecedor (ordem alfabética). */
  private async loadAllGrouped(filters: ReturnType<typeof parseSuggestionFilters>) {
    const items = await collectAllPages<Record<string, unknown>>((page) =>
      this.listUseCase.execute({ ...filters, page, pageSize: 100 }).then((result) => ({
        items: result.items as Array<Record<string, unknown>>,
        hasMore: result.hasMore,
      })),
    );

    const grouped = new Map<string, { fornecedorNome: string; items: Record<string, unknown>[] }>();
    for (const item of items) {
      const key = (item.fornecedorId as string | null) ?? "sem-fornecedor";
      const nome = (item.fornecedorNome as string | undefined) ?? "Sem fornecedor";
      const bucket = grouped.get(key) ?? { fornecedorNome: nome, items: [] };
      bucket.items.push(item);
      grouped.set(key, bucket);
    }

    return Array.from(grouped.values()).sort((a, b) =>
      a.fornecedorNome.localeCompare(b.fornecedorNome),
    );
  }
}

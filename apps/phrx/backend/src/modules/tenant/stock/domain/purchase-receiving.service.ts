import {
  syncStockBalanceCache,
  type StockTx,
} from "./produto-stock.service";
import {
  getLoteQuantidadeFromMovements,
  syncLoteStockBalanceCache,
} from "./lote-stock.service";

/** ENTRADA = estoque inicial; COMPRA = mercadoria de fornecedor. */
export type StockEntryModo = "ENTRADA" | "COMPRA";

export const STOCK_ENTRY_ORIGEM = {
  ENTRADA: "ESTOQUE_INICIAL",
  COMPRA: "FORNECEDOR",
} as const;

type PurchaseLotRecord = {
  id: bigint;
  fornecedorId: bigint | null;
  quantidadeInicial: unknown;
  precoVenda: unknown | null;
};

type PurchaseReceivingTx = StockTx & {
  produto: {
    findUnique: (args: {
      where: { id: bigint };
    }) => Promise<{ id: bigint; nome?: string } | null>;
  };
  lote: {
    findMany: NonNullable<StockTx["lote"]>["findMany"];
    findFirst: (args: {
      where: Record<string, unknown>;
      orderBy?: Record<string, "asc" | "desc">;
    }) => Promise<PurchaseLotRecord | null>;
    create: (args: {
      data: Record<string, unknown>;
    }) => Promise<{ id: bigint }>;
    update: (args: {
      where: { id: bigint };
      data: Record<string, unknown>;
    }) => Promise<{ id: bigint }>;
  };
  estoqueMovimento: {
    create: (args: {
      data: Record<string, unknown>;
    }) => Promise<unknown>;
  };
  historicoPreco: {
    create: (args: {
      data: Record<string, unknown>;
    }) => Promise<unknown>;
  };
};

export interface StockEntryItemInput {
  produtoId: bigint;
  /** Obrigatório em COMPRA; opcional em ENTRADA. Persistido em Lote.fornecedorId. */
  fornecedorId?: bigint | null;
  numeroLote: string;
  dataValidade: string | Date;
  quantidade: number;
  precoCompra: number;
  precoVenda: number | null;
  userId: bigint;
  /** Obrigatório em COMPRA; opcional em ENTRADA. */
  documentoReferencia?: string | null;
  modo: StockEntryModo;
}

export interface StockEntryItemOptions {
  salePriceMode: "truthy" | "nullish";
}

export interface StockEntryItemResult {
  loteId: bigint;
  produtoId: bigint;
  dataValidade: Date;
  estoqueAnterior: number;
  estoqueFinal: number;
  precoVendaLote: number;
  modo: StockEntryModo;
  origem: string;
}

/** @deprecated Use StockEntryItemInput — mantido para compatibilidade de imports de testes. */
export type PurchaseReceivingItemInput = Omit<StockEntryItemInput, "modo"> & {
  fornecedorId: bigint;
  modo?: StockEntryModo;
};

/** @deprecated Use StockEntryItemOptions */
export type PurchaseReceivingItemOptions = StockEntryItemOptions;

/** @deprecated Use StockEntryItemResult */
export type PurchaseReceivingItemResult = StockEntryItemResult;

export function normalizeExpiryDate(value: string | Date): Date {
  const date = value instanceof Date ? new Date(value) : new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new Error("Data de validade inválida");
  }

  date.setUTCHours(0, 0, 0, 0);
  return date;
}

export function getNormalizedExpiryRange(value: string | Date): {
  start: Date;
  end: Date;
} {
  const start = normalizeExpiryDate(value);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 1);
  return { start, end };
}

function normalizeDocumentoReferencia(
  value: string | null | undefined,
): string | null {
  const normalized = value?.trim() ?? "";
  if (!normalized) return null;
  if (normalized.length > 100) {
    throw new Error("Documento de referência não pode exceder 100 caracteres");
  }
  return normalized;
}

function resolvePrecoVendaLoteInput(
  precoVenda: number | null | undefined,
  mode: StockEntryItemOptions["salePriceMode"],
): number {
  if (mode === "truthy") {
    const preco = Number(precoVenda ?? 0);
    if (!Number.isFinite(preco) || preco <= 0) {
      throw new Error(
        "Preço de venda do lote é obrigatório e deve ser superior a zero.",
      );
    }
    return preco;
  }
  if (precoVenda == null) {
    throw new Error("Preço de venda do lote é obrigatório.");
  }
  const preco = Number(precoVenda);
  if (!Number.isFinite(preco) || preco <= 0) {
    throw new Error("Preço de venda do lote deve ser superior a zero.");
  }
  return preco;
}

function resolveEntryRules(input: StockEntryItemInput): {
  tipo: "ENTRADA" | "COMPRA";
  origem: string;
  fornecedorId: bigint | null;
  documentoReferencia: string | null;
} {
  const documentoReferencia = normalizeDocumentoReferencia(
    input.documentoReferencia,
  );
  const fornecedorId = input.fornecedorId ?? null;

  if (input.modo === "COMPRA") {
    if (fornecedorId == null) {
      throw new Error("Fornecedor é obrigatório para compra");
    }
    if (!documentoReferencia) {
      throw new Error(
        "Documento de referência é obrigatório para compra a fornecedor",
      );
    }
    return {
      tipo: "COMPRA",
      origem: STOCK_ENTRY_ORIGEM.COMPRA,
      fornecedorId,
      documentoReferencia,
    };
  }

  return {
    tipo: "ENTRADA",
    origem: STOCK_ENTRY_ORIGEM.ENTRADA,
    fornecedorId,
    documentoReferencia,
  };
}

/**
 * Regista entrada de stock num lote (cria ou reutiliza).
 * ENTRADA → tipo ENTRADA, origem ESTOQUE_INICIAL (documento opcional).
 * COMPRA → tipo COMPRA, origem FORNECEDOR (fornecedor + documento obrigatórios).
 */
export async function receiveStockEntryItem(
  tx: PurchaseReceivingTx,
  input: StockEntryItemInput,
  options: StockEntryItemOptions,
): Promise<StockEntryItemResult> {
  const numeroLote = input.numeroLote.trim();
  if (!numeroLote) {
    throw new Error("Número do lote é obrigatório");
  }

  if (
    input.dataValidade == null ||
    (typeof input.dataValidade === "string" &&
      input.dataValidade.trim().length === 0)
  ) {
    throw new Error("Data de validade é obrigatória");
  }

  if (!Number.isFinite(input.quantidade) || input.quantidade <= 0) {
    throw new Error("Quantidade deve ser superior a zero");
  }

  const rules = resolveEntryRules(input);

  const produto = await tx.produto.findUnique({
    where: { id: input.produtoId },
  });

  if (!produto) {
    throw new Error(`Produto ${input.produtoId} não encontrado`);
  }

  const { start: dataValidadeInicio, end: dataValidadeFim } =
    getNormalizedExpiryRange(input.dataValidade);
  const precoVendaLote = resolvePrecoVendaLoteInput(
    input.precoVenda,
    options.salePriceMode,
  );

  await (
    tx as {
      $executeRaw: (
        query: TemplateStringsArray,
        ...values: unknown[]
      ) => Promise<unknown>;
    }
  ).$executeRaw`SELECT id FROM produtos WHERE id = ${produto.id} FOR UPDATE`;
  await (
    tx as {
      $executeRaw: (
        query: TemplateStringsArray,
        ...values: unknown[]
      ) => Promise<unknown>;
    }
  )
    .$executeRaw`SELECT id FROM lotes WHERE produtoId = ${produto.id} AND deletedAt IS NULL FOR UPDATE`;

  const loteExistente = await tx.lote.findFirst({
    where: {
      produtoId: produto.id,
      numeroLote,
      dataValidade: {
        gte: dataValidadeInicio,
        lt: dataValidadeFim,
      },
      deletedAt: null,
    },
    orderBy: { id: "asc" },
  });

  const precoAnteriorLote = loteExistente
    ? Number(loteExistente.precoVenda ?? 0)
    : 0;
  const estoqueAnterior = loteExistente
    ? await getLoteQuantidadeFromMovements(tx, loteExistente.id)
    : 0;

  const resolvedFornecedorId =
    rules.fornecedorId ??
    (loteExistente ? loteExistente.fornecedorId : null);

  const lote = loteExistente
    ? await tx.lote.update({
        where: { id: loteExistente.id },
        data: {
          quantidadeInicial: { increment: input.quantidade },
          fornecedorId:
            loteExistente.fornecedorId ?? rules.fornecedorId ?? undefined,
          precoCompra: input.precoCompra,
          precoVenda: precoVendaLote,
          ativo: true,
        },
      })
    : await tx.lote.create({
        data: {
          produtoId: produto.id,
          fornecedorId: rules.fornecedorId,
          numeroLote,
          dataValidade: dataValidadeInicio,
          quantidadeInicial: input.quantidade,
          precoCompra: input.precoCompra,
          precoVenda: precoVendaLote,
          ativo: true,
        },
      });

  const estoqueFinal = estoqueAnterior + input.quantidade;

  await tx.estoqueMovimento.create({
    data: {
      produtoId: produto.id,
      loteId: lote.id,
      userId: input.userId,
      tipo: rules.tipo,
      quantidade: input.quantidade,
      estoqueAnterior,
      estoqueFinal,
      origem: rules.origem,
      documentoReferencia: rules.documentoReferencia,
    },
  });

  await syncLoteStockBalanceCache(tx, { id: lote.id });
  await syncStockBalanceCache(tx, produto.id);

  await tx.historicoPreco.create({
    data: {
      produtoId: produto.id,
      fornecedorId: resolvedFornecedorId,
      precoAnterior: precoAnteriorLote,
      precoNovo: precoVendaLote,
      variacao: precoVendaLote - precoAnteriorLote,
    },
  });

  return {
    loteId: lote.id,
    produtoId: produto.id,
    dataValidade: dataValidadeInicio,
    estoqueAnterior,
    estoqueFinal,
    precoVendaLote,
    modo: input.modo,
    origem: rules.origem,
  };
}

/**
 * @deprecated Prefer receiveStockEntryItem with modo explícito.
 * Mantido como alias de COMPRA para callers/testes existentes.
 */
export async function receivePurchaseItemStock(
  tx: PurchaseReceivingTx,
  input: PurchaseReceivingItemInput,
  options: StockEntryItemOptions,
): Promise<StockEntryItemResult> {
  return receiveStockEntryItem(
    tx,
    {
      ...input,
      modo: input.modo ?? "COMPRA",
    },
    options,
  );
}

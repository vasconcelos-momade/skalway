import { z } from "zod";

const optionalIdSchema = z
  .string()
  .trim()
  .regex(/^\d+$/, "Identificador inválido")
  .optional();

const optionalStringSchema = z
  .string()
  .trim()
  .min(1)
  .optional()
  .transform((value) => {
    const normalized = value?.trim();
    return normalized && normalized.length > 0 ? normalized : undefined;
  });

export const entradaCompraBodySchema = z.object({
  produtoId: z.string().trim().min(1, "Produto é obrigatório"),
  fornecedorId: z.string().trim().min(1, "Fornecedor é obrigatório"),
  documentoReferencia: z
    .string()
    .trim()
    .min(1, "Documento de referência é obrigatório para compra a fornecedor")
    .max(100, "Documento de referência não pode exceder 100 caracteres"),
  numeroLote: z.string().trim().min(1, "Número do lote é obrigatório"),
  dataValidade: z.string().trim().min(1, "Data de validade é obrigatória"),
  quantidade: z.coerce.number().positive("Quantidade inválida"),
  precoCompra: z.coerce.number().nonnegative("Preço de compra inválido"),
  precoVenda: z.coerce.number().positive("Preço de venda inválido"),
});

export type EntradaCompraDTO = z.infer<typeof entradaCompraBodySchema>;

export const transferenciaStockBodySchema = z.object({
  produtoId: z.string().trim().min(1, "Produto é obrigatório"),
  loteId: z.string().trim().min(1, "Lote é obrigatório"),
  destinoBranchId: z.string().trim().min(1, "Filial de destino é obrigatória"),
  quantidade: z.coerce.number().positive("Quantidade inválida"),
  documentoReferencia: z
    .string()
    .trim()
    .min(1, "Documento de referência é obrigatório para transferência")
    .max(100, "Documento de referência não pode exceder 100 caracteres"),
});

export type TransferenciaStockDTO = z.infer<typeof transferenciaStockBodySchema>;

export const searchEstoqueQuerySchema = z.object({
  q: optionalStringSchema,
  categoriaId: optionalIdSchema,
  fornecedorId: optionalIdSchema,
  estadoSanitario: z
    .enum(["VALIDO", "RECALL", "EXPIRADO", "QUARENTENA", "BLOQUEADO"])
    .optional(),
  disponibilidade: z
    .enum(["DISPONIVEL", "RESERVADO", "BLOQUEADO", "INDISPONIVEL"])
    .optional(),
  semStock: z.coerce.boolean().optional(),
  aExpirar: z.coerce.boolean().optional(),
  expirado: z.coerce.boolean().optional(),
  validadeAte: optionalStringSchema,
  validadeDe: optionalStringSchema,
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
  sortBy: z
    .enum(["dataValidade", "numeroLote", "quantidadeAtual", "createdAt", "updatedAt"])
    .optional(),
  sortOrder: z.enum(["asc", "desc"]).optional(),
});

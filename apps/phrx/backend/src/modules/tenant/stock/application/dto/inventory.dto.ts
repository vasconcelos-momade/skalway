import { z } from "zod";

export const openInventorySchema = z.object({
  observacao: z.string().trim().max(2000).optional(),
});

export type OpenInventoryDTO = z.infer<typeof openInventorySchema>;

export const recordInventoryCountSchema = z.object({
  estoqueContado: z.coerce.number().nonnegative("Quantidade contada inválida"),
});

export type RecordInventoryCountDTO = z.infer<typeof recordInventoryCountSchema>;

export const addInventoryItemSchema = z.object({
  produtoId: z.string().trim().regex(/^\d+$/, "produtoId inválido"),
  loteId: z.string().trim().regex(/^\d+$/, "loteId inválido"),
  estoqueContado: z.coerce.number().nonnegative("Quantidade contada inválida"),
  observacao: z.string().trim().max(2000).optional(),
});

export type AddInventoryItemDTO = z.infer<typeof addInventoryItemSchema>;

export const listInventoryItemsQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
  nomeGenerico: z.string().trim().min(1).optional(),
  forma: z.string().trim().min(1).optional(),
  fornecedorNome: z.string().trim().min(1).optional(),
});

export type ListInventoryItemsQueryDTO = z.infer<
  typeof listInventoryItemsQuerySchema
>;

export const listInventoryEligibleProductsQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  categoriaId: z.string().trim().regex(/^\d+$/).optional(),
  estadoSanitario: z
    .enum(["VALIDO", "RECALL", "EXPIRADO", "QUARENTENA", "BLOQUEADO"])
    .optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
});

export type ListInventoryEligibleProductsQueryDTO = z.infer<
  typeof listInventoryEligibleProductsQuerySchema
>;

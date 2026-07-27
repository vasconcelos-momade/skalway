import { z } from "zod";

/** Origens canónicas + legados aceites na API (compatibilidade). */
export const cashflowOrigemSchema = z.enum([
  "FATURA",
  "SUPRIMENTO",
  "SANGRIA",
  "DESPESA",
  "ESTORNO",
  "AJUSTE",
  "PEDIDO",
  "COMPRA",
  "PAGAMENTO",
  "REFORCO",
  "OUTRO",
]);

export const cashflowOperationBodySchema = z.object({
  valor: z.coerce.number().positive("Valor deve ser maior que zero"),
  /** Opcional: o use-case aplica origem canónica por tipo se omitido. */
  origem: cashflowOrigemSchema.optional(),
  descricao: z.string().trim().max(500).optional(),
  categoria: z
    .enum([
      "ENERGIA",
      "AGUA",
      "INTERNET",
      "SALARIO",
      "TRANSPORTE",
      "MANUTENCAO",
      "LIMPEZA",
      "IMPOSTO",
      "RENDA",
      "COMPRA_STOCK",
      "OUTRO",
    ])
    .optional(),
  idempotencyKey: z.string().trim().min(8).max(120).optional(),
});

export const cashflowMovementsQuerySchema = z.object({
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
  period: z.string().trim().optional(),
  days: z.coerce.number().int().positive().max(366).optional(),
  from: z.string().trim().optional(),
  to: z.string().trim().optional(),
  search: z.string().trim().optional(),
  sortBy: z.enum(["createdAt", "data", "tipo", "valor", "saldoAnterior", "saldoFinal"]).optional(),
  sortDir: z.enum(["asc", "desc"]).optional(),
});

export type CashflowOperationBody = z.infer<typeof cashflowOperationBodySchema>;
export type CashflowOrigem = z.infer<typeof cashflowOrigemSchema>;
export type CashflowMovementsQuery = z.infer<typeof cashflowMovementsQuerySchema>;

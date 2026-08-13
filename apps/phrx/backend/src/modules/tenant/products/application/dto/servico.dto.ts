import { z } from "zod";

export const servicoIdParamSchema = z.object({
  servicoId: z.string().trim().regex(/^\d+$/, "servicoId inválido"),
});

export const tipoServicoClinicoSchema = z.enum([
  "PESO",
  "PRESSAO_ARTERIAL",
  "TEMPERATURA",
  "GLICEMIA",
  "CONSULTA",
  "INJECAO",
  "CURATIVO",
  "OUTRO",
]);

export const createServicoSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório").max(255),
  tipoServicoClinico: tipoServicoClinicoSchema,
  preco: z.coerce.number().finite().nonnegative("Preço inválido"),
  ativo: z.coerce.boolean().optional(),
  taxRuleId: z
    .union([z.string().regex(/^\d+$/), z.number().int().positive()])
    .optional()
    .nullable()
    .transform((value) => {
      if (value == null || value === "") return null;
      return String(value);
    }),
});

export const updateServicoSchema = z
  .object({
    nome: z.string().trim().min(1).max(255).optional(),
    tipoServicoClinico: tipoServicoClinicoSchema.optional(),
    preco: z.coerce.number().finite().nonnegative().optional(),
    ativo: z.coerce.boolean().optional(),
    taxRuleId: z
      .union([z.string().regex(/^\d+$/), z.number().int().positive(), z.null()])
      .optional()
      .transform((value) => {
        if (value === undefined) return undefined;
        if (value == null || value === "") return null;
        return String(value);
      }),
  })
  .refine((data: Record<string, unknown>) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para actualizar",
  });

export const searchServicosQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  includeInactive: z.coerce.boolean().optional(),
  tipoServicoClinico: tipoServicoClinicoSchema.optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
});

export type CreateServicoDTO = z.infer<typeof createServicoSchema>;
export type UpdateServicoDTO = z.infer<typeof updateServicoSchema>;

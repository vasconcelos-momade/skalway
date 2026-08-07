import { z } from "zod";

export const branchIdParamSchema = z.object({
  branchId: z.string().regex(/^\d+$/, "branchId inválido"),
});

export const updateBranchSettingsSchema = z.object({
  settings: z
    .record(z.string().min(1).max(191), z.unknown())
    .refine((obj) => Object.keys(obj).length > 0, {
      message: "Informe ao menos uma configuração",
    }),
});

export type UpdateBranchSettingsDTO = z.infer<typeof updateBranchSettingsSchema>;

import { z } from "zod";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { parseJsonBody } from "../../../../shared/http/request-validation";
import { CentralSettingsService } from "../../settings/application/central-settings.service";

const updateSettingsSchema = z.object({
  companyName: z.string().trim().min(1),
  companyNuit: z.string().trim().min(1),
  companyEmail: z.string().trim().min(1),
  companyPhone: z.string().trim().min(1),
  companyAddress: z.string().trim().min(1),
  companyCity: z.string().trim().min(1).optional().nullable(),
  companyProvince: z.string().trim().min(1).optional().nullable(),
  companyCountry: z.string().trim().min(2).max(2).optional(),
  companyLogo: z.string().trim().min(1).optional().nullable(),
  mpesaAccountName: z.string().trim().min(1).optional().nullable(),
  mpesaAccountNumber: z.string().trim().min(1).optional().nullable(),
  emolaAccountName: z.string().trim().min(1).optional().nullable(),
  emolaAccountNumber: z.string().trim().min(1).optional().nullable(),
  bankName: z.string().trim().min(1).optional().nullable(),
  bankAccountName: z.string().trim().min(1).optional().nullable(),
  bankAccountNumber: z.string().trim().min(1).optional().nullable(),
  bankAccountNib: z.string().trim().min(1).optional().nullable(),
  bankAccountSwift: z.string().trim().min(1).optional().nullable(),
  bankTransferInstructions: z.string().trim().min(1).optional().nullable(),
  invoiceFooter: z.string().trim().min(1).optional().nullable(),
  receiptFooter: z.string().trim().min(1).optional().nullable(),
  defaultMessage: z.string().trim().min(1).optional().nullable(),
  active: z.coerce.boolean().optional(),
});

export class CentralSettingsController {
  private readonly service = new CentralSettingsService();

  async get(): Promise<Response> {
    const settings = await this.service.get();
    return Response.json(serializeForJson(settings));
  }

  async update(req: Request): Promise<Response> {
    const body = await parseJsonBody(req, updateSettingsSchema);
    try {
      const settings = await this.service.update(body);
      return Response.json(serializeForJson(settings));
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Erro ao actualizar configurações.";
      return Response.json({ error: { message } }, { status: 400 });
    }
  }
}

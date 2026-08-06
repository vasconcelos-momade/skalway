import type { CentralSettingsRepository } from "../../infrastructure/central-settings.repository";
import type {
  CentralSettingsDTO,
  UpdateCentralSettingsInput,
} from "../../domain/central-settings.types";

function isValidNuit(nuit: string): boolean {
  return /^\d{9}$/.test(nuit.trim());
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

function isValidPhone(phone: string): boolean {
  const normalized = phone.replace(/[\s\-()]/g, "");
  return /^\+?\d{8,15}$/.test(normalized);
}

export class UpdateCentralSettingsUseCase {
  constructor(private readonly repository: CentralSettingsRepository) {}

  async execute(input: UpdateCentralSettingsInput): Promise<CentralSettingsDTO> {
    const companyName = input.companyName?.trim() ?? "";
    const companyNuit = input.companyNuit?.trim() ?? "";
    const companyEmail = input.companyEmail?.trim() ?? "";
    const companyPhone = input.companyPhone?.trim() ?? "";
    const companyAddress = input.companyAddress?.trim() ?? "";

    if (!companyName) throw new Error("Nome da Empresa é obrigatório.");
    if (!companyNuit) throw new Error("NUIT é obrigatório.");
    if (!isValidNuit(companyNuit)) {
      throw new Error("NUIT inválido. Deve conter exactamente 9 dígitos.");
    }
    if (!companyEmail) throw new Error("Email é obrigatório.");
    if (!isValidEmail(companyEmail)) throw new Error("Email inválido.");
    if (!companyPhone) throw new Error("Telefone é obrigatório.");
    if (!isValidPhone(companyPhone)) throw new Error("Contacto telefónico inválido.");
    if (!companyAddress) throw new Error("Endereço é obrigatório.");

    return this.repository.updateSingleton({
      ...input,
      companyName,
      companyNuit,
      companyEmail: companyEmail.toLowerCase(),
      companyPhone,
      companyAddress,
      companyCity: input.companyCity?.trim() || null,
      companyProvince: input.companyProvince?.trim() || null,
      companyCountry: (input.companyCountry?.trim() || "MZ").toUpperCase(),
      companyLogo: input.companyLogo?.trim() || null,
      mpesaAccountName: input.mpesaAccountName?.trim() || null,
      mpesaAccountNumber: input.mpesaAccountNumber?.trim() || null,
      emolaAccountName: input.emolaAccountName?.trim() || null,
      emolaAccountNumber: input.emolaAccountNumber?.trim() || null,
      bankName: input.bankName?.trim() || null,
      bankAccountName: input.bankAccountName?.trim() || null,
      bankAccountNumber: input.bankAccountNumber?.trim() || null,
      bankAccountNib: input.bankAccountNib?.trim() || null,
      bankAccountSwift: input.bankAccountSwift?.trim() || null,
      bankTransferInstructions: input.bankTransferInstructions?.trim() || null,
      invoiceFooter: input.invoiceFooter?.trim() || null,
      receiptFooter: input.receiptFooter?.trim() || null,
      defaultMessage: input.defaultMessage?.trim() || null,
    });
  }
}

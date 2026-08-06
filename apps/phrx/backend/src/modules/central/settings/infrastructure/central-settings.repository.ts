import { prismaCentral } from "../../../../infrastructure/prisma/prisma-central.service";
import {
  CENTRAL_SETTINGS_DEFAULTS,
  mapCentralSettings,
  type CentralSettingsDTO,
  type UpdateCentralSettingsInput,
} from "../domain/central-settings.types";

/**
 * Repositório singleton de CentralSettings.
 * Garante um único registo (singletonKey = 1).
 */
export class CentralSettingsRepository {
  private get prisma() {
    return prismaCentral as any;
  }

  async findSingleton(): Promise<CentralSettingsDTO | null> {
    const row = await this.prisma.centralSettings.findFirst({
      where: { singletonKey: 1, deletedAt: null },
    });
    return row ? mapCentralSettings(row) : null;
  }

  async ensureSingleton(
    defaults: UpdateCentralSettingsInput = CENTRAL_SETTINGS_DEFAULTS,
  ): Promise<CentralSettingsDTO> {
    const existing = await this.findSingleton();
    if (existing) return existing;

    const created = await this.prisma.centralSettings.create({
      data: {
        singletonKey: 1,
        companyName: defaults.companyName,
        companyNuit: defaults.companyNuit,
        companyEmail: defaults.companyEmail,
        companyPhone: defaults.companyPhone,
        companyAddress: defaults.companyAddress,
        companyCity: defaults.companyCity ?? null,
        companyProvince: defaults.companyProvince ?? null,
        companyCountry: defaults.companyCountry ?? "MZ",
        companyLogo: defaults.companyLogo ?? null,
        mpesaAccountName: defaults.mpesaAccountName ?? null,
        mpesaAccountNumber: defaults.mpesaAccountNumber ?? null,
        emolaAccountName: defaults.emolaAccountName ?? null,
        emolaAccountNumber: defaults.emolaAccountNumber ?? null,
        bankName: defaults.bankName ?? null,
        bankAccountName: defaults.bankAccountName ?? null,
        bankAccountNumber: defaults.bankAccountNumber ?? null,
        bankAccountNib: defaults.bankAccountNib ?? null,
        bankAccountSwift: defaults.bankAccountSwift ?? null,
        bankTransferInstructions: defaults.bankTransferInstructions ?? null,
        invoiceFooter: defaults.invoiceFooter ?? null,
        receiptFooter: defaults.receiptFooter ?? null,
        defaultMessage: defaults.defaultMessage ?? null,
        active: defaults.active ?? true,
      },
    });

    return mapCentralSettings(created);
  }

  async updateSingleton(
    input: UpdateCentralSettingsInput,
  ): Promise<CentralSettingsDTO> {
    await this.ensureSingleton();

    const updated = await this.prisma.centralSettings.update({
      where: { singletonKey: 1 },
      data: {
        companyName: input.companyName,
        companyNuit: input.companyNuit,
        companyEmail: input.companyEmail,
        companyPhone: input.companyPhone,
        companyAddress: input.companyAddress,
        companyCity: input.companyCity ?? null,
        companyProvince: input.companyProvince ?? null,
        companyCountry: input.companyCountry ?? "MZ",
        companyLogo: input.companyLogo ?? null,
        mpesaAccountName: input.mpesaAccountName ?? null,
        mpesaAccountNumber: input.mpesaAccountNumber ?? null,
        emolaAccountName: input.emolaAccountName ?? null,
        emolaAccountNumber: input.emolaAccountNumber ?? null,
        bankName: input.bankName ?? null,
        bankAccountName: input.bankAccountName ?? null,
        bankAccountNumber: input.bankAccountNumber ?? null,
        bankAccountNib: input.bankAccountNib ?? null,
        bankAccountSwift: input.bankAccountSwift ?? null,
        bankTransferInstructions: input.bankTransferInstructions ?? null,
        invoiceFooter: input.invoiceFooter ?? null,
        receiptFooter: input.receiptFooter ?? null,
        defaultMessage: input.defaultMessage ?? null,
        ...(input.active != null ? { active: input.active } : {}),
        deletedAt: null,
      },
    });

    return mapCentralSettings(updated);
  }
}

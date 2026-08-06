export type CentralSettingsDTO = {
  id: string;
  companyName: string;
  companyNuit: string;
  companyEmail: string;
  companyPhone: string;
  companyAddress: string;
  companyCity: string | null;
  companyProvince: string | null;
  companyCountry: string;
  companyLogo: string | null;
  mpesaAccountName: string | null;
  mpesaAccountNumber: string | null;
  emolaAccountName: string | null;
  emolaAccountNumber: string | null;
  bankName: string | null;
  bankAccountName: string | null;
  bankAccountNumber: string | null;
  bankAccountNib: string | null;
  bankAccountSwift: string | null;
  bankTransferInstructions: string | null;
  invoiceFooter: string | null;
  receiptFooter: string | null;
  defaultMessage: string | null;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
};

export type UpdateCentralSettingsInput = {
  companyName: string;
  companyNuit: string;
  companyEmail: string;
  companyPhone: string;
  companyAddress: string;
  companyCity?: string | null;
  companyProvince?: string | null;
  companyCountry?: string;
  companyLogo?: string | null;
  mpesaAccountName?: string | null;
  mpesaAccountNumber?: string | null;
  emolaAccountName?: string | null;
  emolaAccountNumber?: string | null;
  bankName?: string | null;
  bankAccountName?: string | null;
  bankAccountNumber?: string | null;
  bankAccountNib?: string | null;
  bankAccountSwift?: string | null;
  bankTransferInstructions?: string | null;
  invoiceFooter?: string | null;
  receiptFooter?: string | null;
  defaultMessage?: string | null;
  active?: boolean;
};

export const CENTRAL_SETTINGS_DEFAULTS: UpdateCentralSettingsInput = {
  companyName: "Skalway Technologies, Lda.",
  companyNuit: "400000000",
  companyEmail: "contacto@skalway.com",
  companyPhone: "+258 84 000 0000",
  companyAddress: "Maputo, Moçambique",
  companyCity: "Maputo",
  companyProvince: "Maputo",
  companyCountry: "MZ",
  companyLogo: null,
  mpesaAccountName: "Skalway Technologies, Lda.",
  mpesaAccountNumber: "+258 84 000 0000",
  emolaAccountName: "Skalway Technologies, Lda.",
  emolaAccountNumber: "+258 86 000 0000",
  bankName: "Millennium BIM",
  bankAccountName: "Skalway Technologies, Lda.",
  bankAccountNumber: "123456789",
  bankAccountNib: "00000000000000000000000",
  bankAccountSwift: "BIMOMZMXXXX",
  bankTransferInstructions:
    "Indique o número da factura na descrição da transferência.",
  invoiceFooter: "Obrigado pela confiança na Skalway Technologies.",
  receiptFooter: "Comprovativo emitido pela Central PhRx.",
  defaultMessage: "Documento oficial emitido pela Central PhRx.",
  active: true,
};

export function mapCentralSettings(row: any): CentralSettingsDTO {
  return {
    id: row.id.toString(),
    companyName: String(row.companyName ?? ""),
    companyNuit: String(row.companyNuit ?? ""),
    companyEmail: String(row.companyEmail ?? ""),
    companyPhone: String(row.companyPhone ?? ""),
    companyAddress: String(row.companyAddress ?? ""),
    companyCity: row.companyCity ?? null,
    companyProvince: row.companyProvince ?? null,
    companyCountry: String(row.companyCountry ?? "MZ"),
    companyLogo: row.companyLogo ?? null,
    mpesaAccountName: row.mpesaAccountName ?? null,
    mpesaAccountNumber: row.mpesaAccountNumber ?? null,
    emolaAccountName: row.emolaAccountName ?? null,
    emolaAccountNumber: row.emolaAccountNumber ?? null,
    bankName: row.bankName ?? null,
    bankAccountName: row.bankAccountName ?? null,
    bankAccountNumber: row.bankAccountNumber ?? null,
    bankAccountNib: row.bankAccountNib ?? null,
    bankAccountSwift: row.bankAccountSwift ?? null,
    bankTransferInstructions: row.bankTransferInstructions ?? null,
    invoiceFooter: row.invoiceFooter ?? null,
    receiptFooter: row.receiptFooter ?? null,
    defaultMessage: row.defaultMessage ?? null,
    active: Boolean(row.active ?? true),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

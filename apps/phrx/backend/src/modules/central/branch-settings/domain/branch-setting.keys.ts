export type BranchSettingCategoryValue =
  | "IDENTIDADE"
  | "CONTACTO"
  | "FISCAL"
  | "DOCUMENTO"
  | "IMPRESSAO";

export type BranchSettingSeedDefaults = {
  branchName: string;
  branchCode?: string | null;
  /** Só preencher se o administrador configurar explicitamente — nunca inventar. */
  email?: string | null;
  telefone?: string | null;
  endereco?: string | null;
  cidade?: string | null;
  provincia?: string | null;
  nomeLegal?: string | null;
  nuit?: string | null;
  regimeFiscal?: string | null;
  iva?: number | boolean | null;
  logo?: string | null;
  nomeExibido?: string | null;
  tituloDocumento?: string | null;
  footer?: string | null;
  moeda?: string | null;
  impressaoTipo?: string | null;
  larguraPapel?: number | null;
  printerPadrao?: string | null;
};

export type BranchSettingSeedItem = {
  key: string;
  category: BranchSettingCategoryValue;
  value: unknown;
  description?: string;
};

export const BRANCH_SETTING_KEYS = {
  name: "branch.name",
  code: "branch.code",
  email: "branch.email",
  telefone: "branch.telefone",
  endereco: "branch.endereco",
  cidade: "branch.cidade",
  provincia: "branch.provincia",
  nomeLegal: "fiscal.nomeLegal",
  nuit: "fiscal.nuit",
  regimeFiscal: "fiscal.regimeFiscal",
  iva: "fiscal.iva",
  logo: "documento.logo",
  nomeExibido: "documento.nomeExibido",
  titulo: "documento.titulo",
  footer: "documento.footer",
  moeda: "documento.moeda",
  impressaoTipo: "impressao.tipo",
  larguraPapel: "impressao.larguraPapel",
  printerPadrao: "impressao.printerPadrao",
} as const;

export const BRANCH_SETTING_KEY_CATEGORY: Record<
  string,
  BranchSettingCategoryValue
> = {
  [BRANCH_SETTING_KEYS.name]: "IDENTIDADE",
  [BRANCH_SETTING_KEYS.code]: "IDENTIDADE",
  [BRANCH_SETTING_KEYS.email]: "CONTACTO",
  [BRANCH_SETTING_KEYS.telefone]: "CONTACTO",
  [BRANCH_SETTING_KEYS.endereco]: "CONTACTO",
  [BRANCH_SETTING_KEYS.cidade]: "CONTACTO",
  [BRANCH_SETTING_KEYS.provincia]: "CONTACTO",
  [BRANCH_SETTING_KEYS.nomeLegal]: "FISCAL",
  [BRANCH_SETTING_KEYS.nuit]: "FISCAL",
  [BRANCH_SETTING_KEYS.regimeFiscal]: "FISCAL",
  [BRANCH_SETTING_KEYS.iva]: "FISCAL",
  [BRANCH_SETTING_KEYS.logo]: "DOCUMENTO",
  [BRANCH_SETTING_KEYS.nomeExibido]: "DOCUMENTO",
  [BRANCH_SETTING_KEYS.titulo]: "DOCUMENTO",
  [BRANCH_SETTING_KEYS.footer]: "DOCUMENTO",
  [BRANCH_SETTING_KEYS.moeda]: "DOCUMENTO",
  [BRANCH_SETTING_KEYS.impressaoTipo]: "IMPRESSAO",
  [BRANCH_SETTING_KEYS.larguraPapel]: "IMPRESSAO",
  [BRANCH_SETTING_KEYS.printerPadrao]: "IMPRESSAO",
};

/**
 * Seed inicial da filial.
 * Nome/código = dados reais da Branch.
 * Contacto/NUIT/etc. ficam null salvo configuração explícita.
 */
export function buildDefaultBranchSettings(
  input: BranchSettingSeedDefaults,
): BranchSettingSeedItem[] {
  const branchName = input.branchName.trim();
  return [
    {
      key: BRANCH_SETTING_KEYS.name,
      category: "IDENTIDADE",
      value: branchName,
      description: "Nome da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.code,
      category: "IDENTIDADE",
      value: input.branchCode ?? null,
      description: "Código da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.email,
      category: "CONTACTO",
      value: input.email ?? null,
      description: "E-mail da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.telefone,
      category: "CONTACTO",
      value: input.telefone ?? null,
      description: "Telefone da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.endereco,
      category: "CONTACTO",
      value: input.endereco ?? null,
      description: "Endereço da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.cidade,
      category: "CONTACTO",
      value: input.cidade ?? null,
      description: "Cidade da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.provincia,
      category: "CONTACTO",
      value: input.provincia ?? null,
      description: "Província da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.nomeLegal,
      category: "FISCAL",
      value: input.nomeLegal ?? branchName,
      description: "Nome legal / designação fiscal",
    },
    {
      key: BRANCH_SETTING_KEYS.nuit,
      category: "FISCAL",
      value: input.nuit ?? null,
      description: "NUIT da filial",
    },
    {
      key: BRANCH_SETTING_KEYS.regimeFiscal,
      category: "FISCAL",
      value: input.regimeFiscal ?? "GERAL",
      description: "Regime fiscal",
    },
    {
      key: BRANCH_SETTING_KEYS.iva,
      category: "FISCAL",
      value: input.iva ?? true,
      description: "IVA activo",
    },
    {
      key: BRANCH_SETTING_KEYS.logo,
      category: "DOCUMENTO",
      value: input.logo ?? null,
      description: "Logo para documentos",
    },
    {
      key: BRANCH_SETTING_KEYS.nomeExibido,
      category: "DOCUMENTO",
      value: input.nomeExibido ?? null,
      description: "Nome exibido na fatura",
    },
    {
      key: BRANCH_SETTING_KEYS.titulo,
      category: "DOCUMENTO",
      value: input.tituloDocumento ?? "Fatura",
      description: "Título do documento",
    },
    {
      key: BRANCH_SETTING_KEYS.footer,
      category: "DOCUMENTO",
      value: input.footer ?? null,
      description: "Rodapé do documento",
    },
    {
      key: BRANCH_SETTING_KEYS.moeda,
      category: "DOCUMENTO",
      value: input.moeda ?? "MZN",
      description: "Moeda padrão",
    },
    {
      key: BRANCH_SETTING_KEYS.impressaoTipo,
      category: "IMPRESSAO",
      value: input.impressaoTipo ?? "ESC_POS",
      description: "Tipo de impressão",
    },
    {
      key: BRANCH_SETTING_KEYS.larguraPapel,
      category: "IMPRESSAO",
      value: input.larguraPapel ?? 80,
      description: "Largura do papel (mm)",
    },
    {
      key: BRANCH_SETTING_KEYS.printerPadrao,
      category: "IMPRESSAO",
      value: input.printerPadrao ?? null,
      description: "Impressora padrão da filial",
    },
  ];
}

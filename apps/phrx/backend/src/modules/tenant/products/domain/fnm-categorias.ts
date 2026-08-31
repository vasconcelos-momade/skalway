/** Categorias terapêuticas FNM (Nível 1) — Moçambique. */
export const FNM_CATEGORIAS = [
  { codigoFNM: "ANALGESICOS", nome: "Analgésicos" },
  { codigoFNM: "ANTI_INFLAMATORIOS", nome: "Anti-inflamatórios" },
  { codigoFNM: "ANTIMICROBIANOS", nome: "Antimicrobianos" },
  { codigoFNM: "ANTIPARASITARIOS", nome: "Antiparasitários" },
  { codigoFNM: "ANTIALERGICOS", nome: "Antialérgicos" },
  {
    codigoFNM: "ANTIGRIPAIS_ANTITUSSICOS",
    nome: "Antigripais e Antitússicos",
  },
  { codigoFNM: "CARDIOVASCULARES", nome: "Cardiovasculares" },
  { codigoFNM: "ANTIDIABETICOS", nome: "Antidiabéticos" },
  { codigoFNM: "GASTROINTESTINAIS", nome: "Gastrointestinais" },
  { codigoFNM: "RESPIRATORIOS", nome: "Respiratórios" },
  { codigoFNM: "SISTEMA_NERVOSO", nome: "Sistema Nervoso" },
  { codigoFNM: "VITAMINAS_MINERAIS", nome: "Vitaminas e Minerais" },
  {
    codigoFNM: "HORMONIOS_CONTRACEPTIVOS",
    nome: "Hormônios e Contraceptivos",
  },
  { codigoFNM: "DERMATOLOGICOS", nome: "Dermatológicos" },
  { codigoFNM: "OFTALMICOS", nome: "Oftálmicos" },
  { codigoFNM: "OTOLOGICOS", nome: "Otológicos" },
  { codigoFNM: "GINECOLOGICOS", nome: "Ginecológicos" },
  { codigoFNM: "UROLOGICOS", nome: "Urológicos" },
  {
    codigoFNM: "ANTISSEPTICOS_DESINFETANTES",
    nome: "Antissépticos e Desinfetantes",
  },
  { codigoFNM: "SOLUCOES_REIDRATACAO", nome: "Soluções e Reidratação" },
  { codigoFNM: "ANESTESICOS", nome: "Anestésicos" },
  { codigoFNM: "OUTROS", nome: "Outros" },
] as const;

export type FnmCodigo = (typeof FNM_CATEGORIAS)[number]["codigoFNM"];

export const FNM_CODIGO_ANTIMICROBIANOS = "ANTIMICROBIANOS" as const;

const FNM_NOMES = new Set(
  FNM_CATEGORIAS.map((c) => c.nome.trim().toUpperCase()),
);
const FNM_CODIGOS = new Set(
  FNM_CATEGORIAS.map((c) => c.codigoFNM.trim().toUpperCase()),
);

export function isFnmCategoriaNome(nome: string): boolean {
  const normalized = nome.trim().toUpperCase();
  return FNM_NOMES.has(normalized) || FNM_CODIGOS.has(normalized);
}

export function isAntimicrobianoFnm(categoria?: {
  nome?: string | null;
  codigoFNM?: string | null;
} | null): boolean {
  if (!categoria) return false;
  const codigo = categoria.codigoFNM?.trim().toUpperCase();
  const nome = categoria.nome?.trim().toUpperCase();
  return (
    codigo === FNM_CODIGO_ANTIMICROBIANOS ||
    nome === FNM_CODIGO_ANTIMICROBIANOS ||
    nome === "ANTIMICROBIANOS"
  );
}

export function fnmCategoriaLabel(nome: string): string {
  return nome.replaceAll("_", " ");
}

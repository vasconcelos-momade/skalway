import type {
  PrinterConnectionValue,
  PrinterTypeValue,
} from "./printer.types";

/**
 * Configuração padrão da impressora criada automaticamente com cada filial.
 * Tipo térmico no domínio de negócio → enum Prisma `ESC_POS`.
 * Preparado para coexistir com múltiplas impressoras por filial no futuro.
 */
export const DEFAULT_PRINTER_CONFIG = {
  name: "Caixa Principal",
  type: "ESC_POS" as PrinterTypeValue,
  connection: "NETWORK" as PrinterConnectionValue,
  ip: "192.168.123.100",
  port: 9100,
  model: "XP-80",
  manufacturer: "Xprinter",
  active: true,
} as const;

import {
  gerarFaturaReciboEscpos,
  type FaturaReciboEscposInput,
} from "./fatura-recibo-escpos.template";
import { gerarFaturaReciboPdf80mm } from "./fatura-recibo-pdf-80mm";
import { formatProdutoItemLabel } from "./fatura-recibo-colunas";

function toAscii(value: unknown): string {
  return String(value ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^\x20-\x7E]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function toNumber(value: unknown): number {
  if (typeof value === "number") return Number.isFinite(value) ? value : 0;
  const parsed = Number(String(value ?? "0").replace(",", "."));
  return Number.isFinite(parsed) ? parsed : 0;
}

function toBase64(bytes: Uint8Array): string {
  let binary = "";
  const len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

function resolveTaxaIva(invoice: InvoiceDocumentPayload): number {
  if (invoice.taxaIvaAplicada != null) {
    return toNumber(invoice.taxaIvaAplicada);
  }
  const rates = (invoice.items ?? [])
    .map((item) => toNumber(item.taxaAplicada))
    .filter((rate) => rate > 0);
  if (rates.length === 0) return 0;
  return Math.max(...rates);
}

function resolveEmpresaNome(value: unknown): string {
  const normalized = String(value ?? "").trim();
  return normalized || "Empresa nao configurada";
}

/** FR = recibo térmico 80mm; FT (e restantes) = PDF A4. */
export type InvoiceDocumentMode = "thermal_80mm" | "pdf_a4";

export function resolveInvoiceDocumentMode(
  tipo: string | null | undefined,
): InvoiceDocumentMode {
  return String(tipo ?? "").toUpperCase() === "FR" ? "thermal_80mm" : "pdf_a4";
}

export function isThermalReceiptTipo(tipo: string | null | undefined): boolean {
  return resolveInvoiceDocumentMode(tipo) === "thermal_80mm";
}

export type InvoiceDocumentPayload = {
  id: string;
  numero: string;
  serie?: string | null;
  tipo?: string | null;
  createdAt?: string | Date;
  qrCode?: string | null;
  moeda?: string | null;
  taxaIvaAplicada?: string | number | null;
  empresa?: {
    nome?: string | null;
    nuit?: string | null;
    endereco?: string | null;
    email?: string | null;
    telefone?: string | null;
  } | null;
  cliente?: {
    nome?: string | null;
    documento?: string | null;
  } | null;
  terminal?: {
    nome?: string | null;
    codigo?: string | null;
  } | null;
  user?: {
    name?: string | null;
  } | null;
  items?: Array<{
    descricao?: string | null;
    nomeComercial?: string | null;
    dosagem?: string | null;
    forma?: string | null;
    quantidade?: string | number | null;
    precoUnit?: string | number | null;
    total?: string | number | null;
    taxaAplicada?: string | number | null;
  }>;
  payments?: Array<{
    metodo?: string | null;
    valor?: string | number | null;
    referencia?: string | null;
  }>;
  subtotal?: string | number | null;
  desconto?: string | number | null;
  ivaTotal?: string | number | null;
  total?: string | number | null;
  valorRecebido?: string | number | null;
  troco?: string | number | null;
  estado?: string | null;
};

export class FaturaDocumentService {
  /** Mapeia fatura POS → DTO do template ESC/POS 80mm (scalway-gastro). */
  static toEscposInput(invoice: InvoiceDocumentPayload): FaturaReciboEscposInput {
    return {
      empresa: {
        nome: resolveEmpresaNome(invoice.empresa?.nome),
        nuit: invoice.empresa?.nuit ?? null,
        endereco: invoice.empresa?.endereco ?? null,
        email: invoice.empresa?.email ?? null,
        telefone: invoice.empresa?.telefone ?? null,
      },
      numero: invoice.numero || invoice.id,
      serie: invoice.serie ?? null,
      data: invoice.createdAt ? new Date(invoice.createdAt) : new Date(),
      cliente: invoice.cliente?.nome ?? "Consumidor Final",
      clienteDocumento: invoice.cliente?.documento ?? null,
      terminalCodigo: invoice.terminal?.codigo ?? invoice.terminal?.nome ?? null,
      operador: invoice.user?.name ?? null,
      subtotal: toNumber(invoice.subtotal),
      desconto: toNumber(invoice.desconto),
      taxaIvaAplicada: resolveTaxaIva(invoice),
      ivaTotal: toNumber(invoice.ivaTotal),
      total: toNumber(invoice.total),
      moeda: invoice.moeda ?? "MZN",
      valorRecebido: toNumber(invoice.valorRecebido),
      troco: toNumber(invoice.troco),
      itens: (invoice.items ?? []).map((item) => ({
        nome: formatProdutoItemLabel({
          nomeComercial: item.nomeComercial,
          dosagem: item.dosagem,
          forma: item.forma,
          fallback: item.descricao,
        }),
        quantidade: toNumber(item.quantidade),
        precoUnitario: toNumber(item.precoUnit),
        total: toNumber(item.total),
      })),
      pagamentos: (invoice.payments ?? []).map((payment) => ({
        metodo: String(payment.metodo ?? ""),
        valor: toNumber(payment.valor),
      })),
      qrPayload: invoice.qrCode ?? null,
    };
  }

  static buildPrintArtifact(invoice: InvoiceDocumentPayload): {
    payloadBase64: string;
    fileName: string;
    contentType: string;
  } {
    const escposBytes = gerarFaturaReciboEscpos(
      FaturaDocumentService.toEscposInput(invoice),
    );

    return {
      payloadBase64: toBase64(escposBytes),
      fileName: `fatura-${toAscii(invoice.numero || invoice.id || "documento")}.escpos`,
      contentType: "application/octet-stream",
    };
  }

  /** PDF de visualização com largura de papel térmico 80mm. */
  static buildThermal80mmPdf(invoice: InvoiceDocumentPayload): {
    bytes: Uint8Array;
    fileName: string;
    contentType: string;
  } {
    const bytes = gerarFaturaReciboPdf80mm(
      FaturaDocumentService.toEscposInput(invoice),
    );
    return {
      bytes,
      fileName: `recibo-80mm-${toAscii(invoice.numero || invoice.id || "documento")}.pdf`,
      contentType: "application/pdf",
    };
  }
}

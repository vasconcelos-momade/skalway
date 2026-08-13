import { CentralSettingsService } from "../../../settings/application/central-settings.service";
import { GetInvoiceUseCase } from "../use-cases/get-invoice.use-case";
import {
  renderCentralInvoiceHtml,
  type CentralInvoicePdfView,
} from "../templates/central-invoice.html.template";
import { buildCentralInvoiceLineItems, money } from "./central-invoice-line-items";
import { computePayableAmount } from "./invoice-financial-integrity.service";
import { renderHtmlDocumentToPdf } from "./html-document-pdf.service";

function toDate(value: unknown): Date | null {
  if (!value) return null;
  const d = value instanceof Date ? value : new Date(String(value));
  return Number.isNaN(d.getTime()) ? null : d;
}

/** Formato português: dd/MM/yyyy */
function formatDate(value: unknown): string {
  const d = toDate(value);
  if (!d) return "—";
  return new Intl.DateTimeFormat("pt-PT", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(d);
}

/** Formato português com hora: dd/MM/yyyy HH:mm */
function formatDateTime(value: unknown): string {
  const d = toDate(value);
  if (!d) return "—";
  const hours = String(d.getHours()).padStart(2, "0");
  const minutes = String(d.getMinutes()).padStart(2, "0");
  return `${formatDate(d)} ${hours}:${minutes}`;
}

function formatPeriod(periodStart: unknown, periodEnd: unknown): string {
  const start = formatDate(periodStart);
  const end = formatDate(periodEnd);
  if (start === "—" && end === "—") return "—";
  if (start === "—") return end;
  if (end === "—") return start;
  return `${start} a ${end}`;
}

function statusLabel(status: string): string {
  switch (String(status).toLowerCase()) {
    case "pendente":
      return "Pendente";
    case "parcial":
      return "Parcial";
    case "pago":
      return "Paga";
    case "vencido":
      return "Vencida";
    case "cancelado":
      return "Cancelada";
    default:
      return status;
  }
}

function methodLabel(method: string): string {
  switch (String(method).toUpperCase()) {
    case "CASH":
      return "Cash";
    case "BANK_TRANSFER":
      return "Transferência";
    case "MPESA":
      return "M-Pesa";
    case "EMOLA":
      return "E-Mola";
    default:
      return method;
  }
}

function buildView(invoice: any, issuer: any): CentralInvoicePdfView {
  const currency = invoice.currency || "MZN";
  return {
    issuer: {
      companyName: issuer.companyName,
      companyNuit: issuer.companyNuit,
      companyEmail: issuer.companyEmail,
      companyPhone: issuer.companyPhone,
      companyAddress: issuer.companyAddress,
      companyCity: issuer.companyCity,
      companyProvince: issuer.companyProvince,
      companyCountry: issuer.companyCountry,
      companyLogo: issuer.companyLogo,
      mpesaAccountName: issuer.mpesaAccountName,
      mpesaAccountNumber: issuer.mpesaAccountNumber,
      emolaAccountName: issuer.emolaAccountName,
      emolaAccountNumber: issuer.emolaAccountNumber,
      bankName: issuer.bankName,
      bankAccountName: issuer.bankAccountName,
      bankAccountNumber: issuer.bankAccountNumber,
      bankAccountNib: issuer.bankAccountNib,
      bankAccountSwift: issuer.bankAccountSwift,
      bankTransferInstructions: issuer.bankTransferInstructions,
      invoiceFooter: issuer.invoiceFooter,
      defaultMessage: issuer.defaultMessage,
    },
    customer: {
      companyName: invoice.tenant?.tenantName || "Cliente",
      nuit: invoice.tenant?.nuit,
      contact: invoice.tenant?.contact,
      address: invoice.tenant?.address,
    },
    invoice: {
      number: invoice.number,
      date: formatDate(invoice.createdAt),
      dueDate: formatDate(invoice.dueDate),
      status: statusLabel(invoice.status),
      period: formatPeriod(invoice.periodStart, invoice.periodEnd),
      currency,
      terms: "Transferência / M-Pesa / E-Mola / Cash",
      description: invoice.description,
    },
    items: buildCentralInvoiceLineItems(invoice),
    totals: {
      // Subtotal = valor bruto; Total = Subtotal − Desconto; Em aberto = Total − Pago.
      subtotal: money(invoice.subtotal ?? invoice.amount),
      discount: money(invoice.discount ?? 0),
      paid: money(invoice.paidAmount),
      remaining: money(
        invoice.remainingAmount ??
          computePayableAmount(
            Number(invoice.amount),
            Number(invoice.discount ?? 0),
          ) - Number(invoice.paidAmount ?? 0),
      ),
      total: money(
        invoice.payableAmount ??
          computePayableAmount(
            Number(invoice.amount),
            Number(invoice.discount ?? 0),
          ),
      ),
    },
    payments: (invoice.payments ?? []).map((p: any) => ({
      reference: p.reference || "—",
      method: methodLabel(p.method),
      amount: money(p.amount),
      status: statusLabel(p.status),
      date: p.confirmedAt
        ? formatDateTime(p.confirmedAt)
        : formatDateTime(p.createdAt),
    })),
  };
}

export async function generateCentralInvoicePdf(
  tenantId: string,
  invoiceId: string,
): Promise<Uint8Array> {
  const [invoice, issuer] = await Promise.all([
    new GetInvoiceUseCase().execute({ tenantId, invoiceId }),
    new CentralSettingsService().get(),
  ]);

  const view = buildView(invoice, issuer);
  const html = renderCentralInvoiceHtml(view);
  const payable = Number(
    invoice.payableAmount ??
      computePayableAmount(
        Number(invoice.amount),
        Number(invoice.discount ?? 0),
      ),
  );

  const fallback = [
    `${issuer.companyName} — Factura SaaS`,
    `NUIT: ${issuer.companyNuit}`,
    `Cliente: ${invoice.tenant?.tenantName ?? "—"}`,
    `Numero: ${invoice.number}`,
    `Total: ${payable} ${invoice.currency}`,
    issuer.invoiceFooter || "",
  ];

  return renderHtmlDocumentToPdf(html, fallback);
}

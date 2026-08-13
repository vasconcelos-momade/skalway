import { CentralSettingsService } from "../../../settings/application/central-settings.service";
import { GetInvoiceUseCase } from "../use-cases/get-invoice.use-case";
import {
  renderCentralInvoiceHtml,
  type CentralInvoiceLineItem,
  type CentralInvoicePdfView,
} from "../templates/central-invoice.html.template";
import { renderHtmlDocumentToPdf } from "./html-document-pdf.service";

function money(value: unknown, digits = 2): string {
  const n = Number(value ?? 0);
  if (!Number.isFinite(n)) return (0).toFixed(digits);
  return n.toFixed(digits);
}

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

function resolveContractMonths(invoice: any): number {
  const start = invoice.periodStart ? new Date(invoice.periodStart) : null;
  const end = invoice.periodEnd ? new Date(invoice.periodEnd) : null;
  if (
    start &&
    end &&
    !Number.isNaN(start.getTime()) &&
    !Number.isNaN(end.getTime())
  ) {
    const monthDiff =
      (end.getUTCFullYear() - start.getUTCFullYear()) * 12 +
      (end.getUTCMonth() - start.getUTCMonth()) +
      1;
    return Math.max(1, monthDiff);
  }
  return 1;
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

function buildLineItems(invoice: any): CentralInvoiceLineItem[] {
  const items: CentralInvoiceLineItem[] = [];
  const planName = invoice.planName || "Plano SaaS";
  const planPrice = Number(invoice.planMonthlyPrice);
  const extraBranches = Number(
    invoice.snapshotExtraBranches ?? invoice.extraBranches ?? 0,
  );
  const extraPrice = Number(invoice.extraBranchPrice ?? 0);
  const contractMonths = resolveContractMonths(invoice);
  const contractPeriodLabel = `Período do contrato: ${contractMonths} ${contractMonths === 1 ? "mês" : "meses"}`;

  if (Number.isFinite(planPrice) && planPrice >= 0) {
    const lineAmount = planPrice * contractMonths;
    items.push({
      item: 1,
      description: `Subscrição ${planName}${invoice.planSlug ? ` (${invoice.planSlug})` : ""} — mensalidade\n${contractPeriodLabel}`,
      qty: String(contractMonths),
      unitPrice: money(planPrice),
      amount: money(lineAmount),
    });
  }

  if (extraBranches > 0 && Number.isFinite(extraPrice)) {
    const lineAmount = extraBranches * extraPrice * contractMonths;
    items.push({
      item: items.length + 1,
      description: `Filiais extra (${extraBranches} × ${money(extraPrice)} MZN/mês)\n${contractPeriodLabel}`,
      qty: String(extraBranches),
      unitPrice: money(extraPrice * contractMonths),
      amount: money(lineAmount),
    });
  }

  if (items.length === 0) {
    items.push({
      item: 1,
      description:
        `${invoice.description || `Factura SaaS ${invoice.number}`}\n${contractPeriodLabel}`,
      qty: String(contractMonths),
      unitPrice: money(
        contractMonths > 0
          ? Number(invoice.amount) / contractMonths
          : invoice.amount,
      ),
      amount: money(invoice.amount),
    });
  }

  return items;
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
    items: buildLineItems(invoice),
    totals: {
      subtotal: money(invoice.subtotal ?? invoice.amount),
      discount: money(invoice.discount ?? 0),
      paid: money(invoice.paidAmount),
      remaining: money(invoice.remainingAmount),
      total: money(invoice.amount),
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

  const fallback = [
    `${issuer.companyName} — Factura SaaS`,
    `NUIT: ${issuer.companyNuit}`,
    `Cliente: ${invoice.tenant?.tenantName ?? "—"}`,
    `Numero: ${invoice.number}`,
    `Total: ${invoice.amount} ${invoice.currency}`,
    issuer.invoiceFooter || "",
  ];

  return renderHtmlDocumentToPdf(html, fallback);
}

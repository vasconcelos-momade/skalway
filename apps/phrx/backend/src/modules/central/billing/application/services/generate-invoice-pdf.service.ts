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

function formatDate(value: unknown): string {
  if (!value) return "—";
  const d = value instanceof Date ? value : new Date(String(value));
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("pt-MZ", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
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

  if (Number.isFinite(planPrice) && planPrice >= 0) {
    items.push({
      item: 1,
      description: `Subscrição ${planName}${invoice.planSlug ? ` (${invoice.planSlug})` : ""} — mensalidade`,
      qty: "1",
      unitPrice: money(planPrice),
      amount: money(planPrice),
    });
  }

  if (extraBranches > 0 && Number.isFinite(extraPrice)) {
    items.push({
      item: items.length + 1,
      description: `Filiais extra (${extraBranches} × ${money(extraPrice)} MZN)`,
      qty: String(extraBranches),
      unitPrice: money(extraPrice),
      amount: money(extraBranches * extraPrice),
    });
  }

  if (items.length === 0) {
    items.push({
      item: 1,
      description:
        invoice.description ||
        `Factura SaaS ${invoice.number}`,
      qty: "1",
      unitPrice: money(invoice.amount),
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
      companyName:
        invoice.tenant?.companyName ||
        invoice.tenant?.tenantName ||
        "Cliente",
      nuit: invoice.tenant?.nuit,
      contact: invoice.tenant?.contact,
      address: invoice.tenant?.address,
    },
    invoice: {
      number: invoice.number,
      date: formatDate(invoice.createdAt),
      dueDate: formatDate(invoice.dueDate),
      status: statusLabel(invoice.status),
      period: invoice.period || "—",
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
      date: formatDate(p.confirmedAt || p.createdAt),
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
    `Cliente: ${invoice.tenant?.companyName ?? "—"}`,
    `Numero: ${invoice.number}`,
    `Total: ${invoice.amount} ${invoice.currency}`,
    issuer.invoiceFooter || "",
  ];

  return renderHtmlDocumentToPdf(html, fallback);
}

import type { CentralInvoiceLineItem } from "../templates/central-invoice.html.template";

export function money(value: unknown, digits = 2): string {
  const n = Number(value ?? 0);
  if (!Number.isFinite(n)) return (0).toFixed(digits);
  return n.toFixed(digits);
}

/**
 * Meses facturados a partir de periodStart/periodEnd.
 * Períodos criados com addMonthsUTC(start, n) - 1ms caem no mês anterior ao
 * aniversário; NÃO usar +1 inclusivo (Aug→Sep virava 2 em vez de 1).
 */
export function resolveContractMonths(invoice: {
  periodStart?: unknown;
  periodEnd?: unknown;
}): number {
  const start = invoice.periodStart ? new Date(invoice.periodStart as any) : null;
  const end = invoice.periodEnd ? new Date(invoice.periodEnd as any) : null;
  if (
    start &&
    end &&
    !Number.isNaN(start.getTime()) &&
    !Number.isNaN(end.getTime()) &&
    end.getTime() >= start.getTime()
  ) {
    const monthDiff =
      (end.getUTCFullYear() - start.getUTCFullYear()) * 12 +
      (end.getUTCMonth() - start.getUTCMonth());
    return Math.max(1, monthDiff);
  }
  return 1;
}

/**
 * Linhas da factura SaaS:
 * - Plano: QTD = 1 (mensalidade do período); meses só na descrição.
 * - Filiais adicionais: QTD = número de branches extras.
 */
export function buildCentralInvoiceLineItems(invoice: any): CentralInvoiceLineItem[] {
  const items: CentralInvoiceLineItem[] = [];
  const planName = invoice.planName || "Plano SaaS";
  const planPrice = Number(invoice.planMonthlyPrice);
  const extraBranches = Math.max(
    0,
    Number(invoice.snapshotExtraBranches ?? invoice.extraBranches ?? 0),
  );
  const extraPrice = Number(invoice.extraBranchPrice ?? 0);
  const contractMonths = resolveContractMonths(invoice);
  const contractPeriodLabel = `Período do contrato: ${contractMonths} ${contractMonths === 1 ? "mês" : "meses"}`;

  if (Number.isFinite(planPrice) && planPrice >= 0) {
    const lineAmount = planPrice * contractMonths;
    items.push({
      item: 1,
      description: `Subscrição ${planName}${invoice.planSlug ? ` (${invoice.planSlug})` : ""} — mensalidade\n${contractPeriodLabel}`,
      qty: "1",
      unitPrice: money(lineAmount),
      amount: money(lineAmount),
    });
  }

  if (extraBranches > 0 && Number.isFinite(extraPrice) && extraPrice >= 0) {
    const unitForPeriod = extraPrice * contractMonths;
    const lineAmount = extraBranches * unitForPeriod;
    items.push({
      item: items.length + 1,
      description: `Filiais adicionais (${extraBranches} × ${money(extraPrice)} MZN/mês)\n${contractPeriodLabel}`,
      qty: String(extraBranches),
      unitPrice: money(unitForPeriod),
      amount: money(lineAmount),
    });
  }

  if (items.length === 0) {
    items.push({
      item: 1,
      description:
        `${invoice.description || `Factura SaaS ${invoice.number}`}\n${contractPeriodLabel}`,
      qty: "1",
      unitPrice: money(invoice.amount),
      amount: money(invoice.amount),
    });
  }

  return items;
}

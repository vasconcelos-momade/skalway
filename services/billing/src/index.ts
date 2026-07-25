/**
 * @skalway/billing
 *
 * Core partilhado: regras financeiras, períodos, pricing e numeração fiscal.
 * Use-cases Prisma / rotas HTTP / email ficam no produto (PhRx).
 */
export {
  assertInvoiceAmounts,
  computeRemainingAmount,
  deriveInvoiceStatus,
} from "./invoice-financial-integrity";

export {
  DEFAULT_INVOICE_CURRENCY,
  mapInvoiceFinancialFields,
} from "./invoice-response.mapper";

export { toCents, fromCents } from "./money";

export {
  parseReferenceDate,
  startOfMonthUTC,
  endOfMonthUTC,
  addDaysUTC,
  addMonthsUTC,
  endOfDayUTC,
} from "./billing-period";

export { calculatePlanTotals } from "./plan-pricing";
export type { PlanPricingInput, PlanPricingResult } from "./plan-pricing";

export { formatInvoiceNumber } from "./fiscal-number";

export {
  buildMonthlyInvoiceDescription,
  buildTrialInvoiceDescription,
} from "./invoice-copy";

export const service = {
  name: "billing",
  version: "0.1.0",
  responsibilities: [
    "invoice-integrity",
    "plan-pricing",
    "billing-periods",
    "fiscal-numbers",
  ] as const,
} as const;

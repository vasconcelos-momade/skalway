import {
  computePayableAmount,
  computeRemainingAmount,
} from "./invoice-financial-integrity";

/** Moeda padrão SaaS (schema central não persiste currency por linha). */
export const DEFAULT_INVOICE_CURRENCY = "MZN";

export function mapInvoiceFinancialFields(invoice: {
  amount: unknown;
  paidAmount: unknown;
  discount?: unknown;
}): {
  amount: number;
  discount: number;
  paidAmount: number;
  remainingAmount: number;
  payableAmount: number;
} {
  const amount = Number(invoice.amount);
  const paidAmount = Number(invoice.paidAmount);
  const discount = Number(invoice.discount ?? 0);
  return {
    amount,
    discount,
    paidAmount,
    payableAmount: computePayableAmount(amount, discount),
    remainingAmount: computeRemainingAmount(amount, paidAmount, discount),
  };
}

/**
 * Integridade mínima fatura ↔ pagamentos.
 * remainingAmount = (amount - discount) - paidAmount.
 */

export function assertInvoiceAmounts(
  amount: number,
  paidAmount: number,
  discount = 0,
): void {
  if (paidAmount < 0) {
    throw new Error("paidAmount não pode ser negativo.");
  }
  if (discount < 0) {
    throw new Error("discount não pode ser negativo.");
  }
  if (discount > amount) {
    throw new Error("discount não pode exceder o valor da fatura (amount).");
  }
  const payable = Math.round((amount - discount) * 100) / 100;
  if (paidAmount > payable) {
    throw new Error("paidAmount não pode exceder o valor líquido da fatura.");
  }
}

export function computePayableAmount(amount: number, discount = 0): number {
  const safeDiscount = Number.isFinite(discount) ? Math.max(0, discount) : 0;
  return Math.round((amount - safeDiscount) * 100) / 100;
}

export function computeRemainingAmount(
  amount: number,
  paidAmount: number,
  discount = 0,
): number {
  assertInvoiceAmounts(amount, paidAmount, discount);
  return Math.round((computePayableAmount(amount, discount) - paidAmount) * 100) / 100;
}

export function deriveInvoiceStatus(
  amount: number,
  paidAmount: number,
  current: string,
  discount = 0,
): "pendente" | "parcial" | "pago" | "vencido" | "cancelado" {
  assertInvoiceAmounts(amount, paidAmount, discount);
  if (current === "cancelado") {
    return "cancelado";
  }
  const payable = computePayableAmount(amount, discount);
  if (paidAmount <= 0) {
    return current === "vencido" ? "vencido" : "pendente";
  }
  if (paidAmount >= payable) return "pago";
  return "parcial";
}

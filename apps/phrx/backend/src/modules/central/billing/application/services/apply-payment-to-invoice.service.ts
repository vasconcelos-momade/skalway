import {
  assertInvoiceAmounts,
  computeRemainingAmount,
  deriveInvoiceStatus,
} from "./invoice-financial-integrity.service";
import { mapInvoiceFinancialFields } from "./invoice-response.mapper";
import { addDaysUTC } from "@skalway/billing";

export interface ApplyPaymentToInvoiceInput {
  tenantId: string;
  paymentId: bigint;
  confirmedByUserId?: string | null;
}

export interface ApplyPaymentToInvoiceResult {
  payment: {
    id: string;
    status: string;
    confirmedAt: Date;
  };
  invoice: {
    id: string;
    number: string;
    amount: number;
    paidAmount: number;
    remainingAmount: number;
    status: string;
    paidAt: Date | null;
  };
}

/**
 * Confirma um pagamento pendente e actualiza a fatura associada (transacção Prisma).
 * Quando a fatura fica paga, regista o período coberto e avança nextBillingAt / currentPeriodEnd
 * para suportar pagamento antecipado sem gerar faturas duplicadas.
 */
export async function applyPaymentToInvoice(
  tx: any,
  input: ApplyPaymentToInvoiceInput,
): Promise<ApplyPaymentToInvoiceResult> {
  const payment = await tx.payment.findFirst({
    where: {
      id: input.paymentId,
      tenantId: BigInt(input.tenantId),
      deletedAt: null,
    },
    include: { invoice: true },
  });

  if (!payment) {
    throw new Error("Pagamento não encontrado.");
  }

  if (payment.status === "confirmado") {
    throw new Error("Pagamento já confirmado.");
  }

  if (payment.status === "cancelado" || payment.status === "falhado") {
    throw new Error(`Não é possível confirmar pagamento com status ${payment.status}.`);
  }

  if (!payment.invoice) {
    throw new Error("Pagamento sem fatura associada.");
  }

  const invoice = payment.invoice;
  const amount = Number(invoice.amount);
  const discount = Number(invoice.discount ?? 0);
  const paidBefore = Number(invoice.paidAmount);
  const paymentAmount = Number(payment.amount);
  const paidAfter = Math.round((paidBefore + paymentAmount) * 100) / 100;

  assertInvoiceAmounts(amount, paidAfter, discount);
  const status = deriveInvoiceStatus(
    amount,
    paidAfter,
    String(invoice.status),
    discount,
  );
  const confirmedAt = new Date();

  const coversFrom = invoice.periodStart ?? payment.coversFrom ?? null;
  const coversTo = invoice.periodEnd ?? payment.coversTo ?? null;
  let monthsCovered = payment.monthsCovered as number | null;
  if (monthsCovered == null && coversFrom && coversTo) {
    const from = new Date(coversFrom);
    const to = new Date(coversTo);
    const monthDiff =
      (to.getUTCFullYear() - from.getUTCFullYear()) * 12 +
      (to.getUTCMonth() - from.getUTCMonth()) +
      1;
    monthsCovered = Math.max(1, monthDiff);
  }

  await tx.payment.update({
    where: { id: payment.id },
    data: {
      status: "confirmado",
      confirmedAt,
      confirmedBy: input.confirmedByUserId ? BigInt(input.confirmedByUserId) : null,
      updatedBy: input.confirmedByUserId ? BigInt(input.confirmedByUserId) : null,
      coversFrom,
      coversTo,
      monthsCovered,
    },
  });

  const updatedInvoice = await tx.invoice.update({
    where: { id: invoice.id },
    data: {
      paidAmount: paidAfter,
      remainingAmount: computeRemainingAmount(amount, paidAfter, discount),
      status,
      paidAt: status === "pago" ? confirmedAt : invoice.paidAt,
    },
    select: {
      id: true,
      number: true,
      amount: true,
      discount: true,
      paidAmount: true,
      status: true,
      paidAt: true,
    },
  });

  if (status === "pago") {
    await tx.tenant.update({
      where: { id: BigInt(input.tenantId) },
      data: { status: "ativo" },
    });

    if (coversTo) {
      const coverageEnd = new Date(coversTo);
      const nextBillingAt = addDaysUTC(coverageEnd, 1);
      const subscription = await tx.subscription.findFirst({
        where: { id: invoice.subscriptionId, deletedAt: null },
        select: { id: true, nextBillingAt: true, currentPeriodEnd: true },
      });

      if (subscription) {
        const currentNext = subscription.nextBillingAt
          ? new Date(subscription.nextBillingAt)
          : null;
        const currentPeriodEnd = subscription.currentPeriodEnd
          ? new Date(subscription.currentPeriodEnd)
          : null;

        await tx.subscription.update({
          where: { id: subscription.id },
          data: {
            status: "ativo",
            lastBillingAt: confirmedAt,
            nextBillingAt:
              !currentNext || nextBillingAt > currentNext
                ? nextBillingAt
                : currentNext,
            currentPeriodEnd:
              !currentPeriodEnd || coverageEnd > currentPeriodEnd
                ? coverageEnd
                : currentPeriodEnd,
          },
        });
      }
    } else {
      await tx.subscription.updateMany({
        where: { id: invoice.subscriptionId, deletedAt: null },
        data: {
          status: "ativo",
          lastBillingAt: confirmedAt,
        },
      });
    }
  }

  const financials = mapInvoiceFinancialFields(updatedInvoice);

  return {
    payment: {
      id: payment.id.toString(),
      status: "confirmado",
      confirmedAt,
    },
    invoice: {
      id: updatedInvoice.id.toString(),
      number: updatedInvoice.number,
      ...financials,
      status: updatedInvoice.status,
      paidAt: updatedInvoice.paidAt,
    },
  };
}

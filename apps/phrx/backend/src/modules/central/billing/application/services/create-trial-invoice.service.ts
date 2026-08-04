import { SubscriptionBillingService } from "./subscription-billing.service";
import {
  addMonthsUTC,
  buildTrialInvoiceDescription,
} from "@skalway/billing";

export interface CreateTrialInvoiceInput {
  tx: any;
  tenantId: bigint;
  subscriptionId: bigint;
  plan: {
    name: string;
    slug: string;
    monthlyPrice: unknown;
    includedBranches?: unknown;
    extraBranchPrice?: unknown;
    isEnterprise?: boolean;
  };
  startDate: Date;
  trialEndsAt: Date;
  branchesUsed?: number;
}

export interface CreateTrialInvoiceResult {
  invoiceId: string;
  invoiceNumber: string;
  amount: string;
  dueDate: Date;
  periodStart: Date;
  periodEnd: Date;
}

/**
 * Fatura inicial do trial — delega em SubscriptionBillingService.
 * Vencimento = fim do trial; período = primeiro mês após o trial.
 */
export async function createTrialInvoice(
  input: CreateTrialInvoiceInput,
): Promise<CreateTrialInvoiceResult | null> {
  const branchesUsed = Math.max(1, input.branchesUsed ?? 1);
  const periodStart = new Date(input.trialEndsAt);
  const periodEnd = new Date(addMonthsUTC(periodStart, 1).getTime() - 1);
  const dueDate = new Date(input.trialEndsAt);

  const totals = SubscriptionBillingService.calculateTotals(input.plan, branchesUsed);
  if (totals.totalCents <= 0) {
    return null;
  }

  const description = buildTrialInvoiceDescription({
    planName: String(input.plan.name),
    planSlug: String(input.plan.slug),
    periodStart,
    periodEnd,
    branchesUsed,
    includedBranches: totals.includedBranches,
    extraBranches: totals.extraBranches,
  });

  const billed = await SubscriptionBillingService.billSubscriptionPeriod({
    tx: input.tx,
    subscription: {
      id: input.subscriptionId,
      tenantId: input.tenantId,
      plan: input.plan,
    },
    periodStart,
    periodEnd,
    dueDate,
    description,
    branchesUsedOverride: branchesUsed,
    fiscalReferenceDate: input.startDate,
    upsertSnapshot: false,
    // Datas do trial já foram definidas no CreateTenant.
    skipSubscriptionDateUpdate: true,
  });

  if (!billed.invoiceId || !billed.invoiceNumber) {
    return null;
  }

  return {
    invoiceId: billed.invoiceId,
    invoiceNumber: billed.invoiceNumber,
    amount: billed.total,
    dueDate,
    periodStart,
    periodEnd,
  };
}

import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import { SubscriptionBillingService } from "../services/subscription-billing.service";
import { fromCents, addMonthsUTC } from "@skalway/billing";

export interface GetTenantSubscriptionDTO {
  tenantId: string;
}

/**
 * DTO completo da subscrição para a UI Central.
 * Todos os totais/extras vêm do SubscriptionBillingService — sem cálculo no frontend.
 */
export class GetTenantSubscriptionUseCase {
  async execute(data: GetTenantSubscriptionDTO) {
    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const subscription = await prisma.subscription.findFirst({
        where: {
          tenantId: BigInt(data.tenantId),
          deletedAt: null,
        },
        include: {
          plan: {
            select: {
              id: true,
              name: true,
              slug: true,
              monthlyPrice: true,
              includedBranches: true,
              extraBranchPrice: true,
              isEnterprise: true,
              trialDays: true,
              billingIntervalMonths: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
      });

      if (!subscription) {
        throw new Error("Subscrição não encontrada para este tenant.");
      }

      const activeBranches = await SubscriptionBillingService.countActiveBranches(
        BigInt(data.tenantId),
        prisma,
      );
      // Fonte de verdade: filiais activas (não o cache).
      const branchesUsed = activeBranches;
      const totals = SubscriptionBillingService.calculateTotals(
        subscription.plan,
        branchesUsed,
      );

      const baseMonthlyPrice = Number(fromCents(totals.planMonthlyPriceCents));
      const extraBranchPrice = Number(fromCents(totals.extraBranchPriceCents));
      const estimatedMonthlyTotal = Number(fromCents(totals.totalCents));
      const extraBranchesCharge = Number(
        fromCents(totals.extraBranches * totals.extraBranchPriceCents),
      );

      let nextPeriodStart: Date | null = null;
      let nextPeriodEnd: Date | null = null;
      if (subscription.nextBillingAt) {
        nextPeriodStart = new Date(subscription.nextBillingAt);
        nextPeriodEnd = new Date(
          addMonthsUTC(
            nextPeriodStart,
            Number(subscription.plan.billingIntervalMonths ?? 1),
          ).getTime() - 1,
        );
      }

      const lastInvoice = await prisma.invoice.findFirst({
        where: {
          subscriptionId: subscription.id,
          deletedAt: null,
        },
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          number: true,
          amount: true,
          status: true,
          dueDate: true,
          paidAt: true,
        },
      });

      const pendingTrialInvoice =
        subscription.status === "trial"
          ? await prisma.invoice.findFirst({
              where: {
                subscriptionId: subscription.id,
                deletedAt: null,
                status: { in: ["pendente", "parcial"] },
              },
              orderBy: { createdAt: "asc" },
              select: {
                id: true,
                number: true,
                amount: true,
                status: true,
                dueDate: true,
              },
            })
          : null;

      return {
        id: subscription.id.toString(),
        tenantId: subscription.tenantId.toString(),
        status: subscription.status,
        planName: String(subscription.plan.name),
        planSlug: String(subscription.plan.slug),
        isEnterprise: Boolean(subscription.plan.isEnterprise),
        trialDays: Number(subscription.plan.trialDays ?? 14),
        branchesUsed,
        activeBranches,
        includedBranches: totals.includedBranches,
        extraBranches: totals.extraBranches,
        baseMonthlyPrice,
        monthlyPrice: baseMonthlyPrice,
        extraBranchPrice,
        estimatedMonthlyTotal,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        trialEndsAt: subscription.trialEndsAt,
        currentPeriodEnd: subscription.currentPeriodEnd,
        lastBillingAt: subscription.lastBillingAt,
        nextBillingAt: subscription.nextBillingAt,
        estimatedNextInvoice: {
          amount: estimatedMonthlyTotal,
          currency: "MZN",
          periodStart: nextPeriodStart,
          periodEnd: nextPeriodEnd,
          branchesUsed,
          includedBranches: totals.includedBranches,
          extraBranches: totals.extraBranches,
          breakdown: {
            planMonthlyPrice: baseMonthlyPrice,
            extraBranchesCharge,
            extraBranchPrice,
          },
        },
        lastInvoice: lastInvoice
          ? {
              id: lastInvoice.id.toString(),
              number: String(lastInvoice.number),
              amount: Number(lastInvoice.amount),
              status: String(lastInvoice.status),
              dueDate: lastInvoice.dueDate,
              paidAt: lastInvoice.paidAt,
            }
          : null,
        pendingTrialInvoice: pendingTrialInvoice
          ? {
              id: pendingTrialInvoice.id.toString(),
              number: String(pendingTrialInvoice.number),
              amount: Number(pendingTrialInvoice.amount),
              status: String(pendingTrialInvoice.status),
              dueDate: pendingTrialInvoice.dueDate,
            }
          : null,
        plan: {
          id: subscription.plan.id,
          name: subscription.plan.name,
          slug: subscription.plan.slug,
          monthlyPrice: baseMonthlyPrice,
          includedBranches: totals.includedBranches,
          extraBranchPrice,
          isEnterprise: Boolean(subscription.plan.isEnterprise),
          trialDays: Number(subscription.plan.trialDays ?? 14),
        },
      };
    });
  }
}

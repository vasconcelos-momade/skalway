import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { allocateInvoiceFiscal } from "./allocate-invoice-fiscal.service";
import {
  assertInvoiceAmounts,
  deriveInvoiceStatus,
  computeRemainingAmount,
  addDaysUTC,
  fromCents,
  calculatePlanTotals,
  type PlanPricingInput,
} from "@skalway/billing";

export interface BillingTotals {
  includedBranches: number;
  extraBranches: number;
  planMonthlyPriceCents: number;
  extraBranchPriceCents: number;
  subtotalCents: number;
  totalCents: number;
}

export interface BillSubscriptionPeriodInput {
  tx: any;
  subscription: {
    id: bigint;
    tenantId: bigint;
    plan: PlanPricingInput & { name?: string; slug?: string; active?: boolean };
  };
  periodStart: Date;
  periodEnd: Date;
  dueDate: Date;
  description: string;
  /** Se true, não actualiza lastBillingAt/nextBillingAt/currentPeriodEnd. */
  skipSubscriptionDateUpdate?: boolean;
  /** Contagem explícita (ex.: trial com 1 branch); senão conta no período. */
  branchesUsedOverride?: number;
  /** Referência fiscal (default: periodStart). */
  fiscalReferenceDate?: Date;
  /** Se false, cria snapshot sem upsert (trial). Default true. */
  upsertSnapshot?: boolean;
  /** Multiplicador do valor mensal (ex.: faturação trimestral = 3). Default 1. */
  periodMonths?: number;
}

export interface BillSubscriptionPeriodResult {
  branchesUsed: number;
  includedBranches: number;
  extraBranches: number;
  subtotal: string;
  total: string;
  snapshotAction: "created" | "updated";
  invoiceAction: "created" | "updated" | "kept_paid" | "skipped_free";
  invoiceId?: string;
  invoiceNumber?: string;
  snapshotId?: string;
}

/**
 * Serviço de domínio de faturação da subscrição.
 * Centraliza: contagem de filiais, extras, snapshot, invoice e datas.
 * Controllers / UseCases não devem calcular valores financeiros.
 */
export class SubscriptionBillingService {
  /** Fonte de verdade actual: filiais activas não apagadas. */
  static async countActiveBranches(
    tenantId: bigint,
    prisma: any = prismaCentralUnscoped as any,
  ): Promise<number> {
    const count = await prisma.branch.count({
      where: {
        tenantId,
        active: true,
        deletedAt: null,
      },
    });
    return Math.max(count, 0);
  }

  /**
   * Contagem para um período de facturação:
   * - activa
   * - criada até ao fim do período
   * - não apagada, ou apagada após o início do período
   */
  static async countActiveBranchesForPeriod(
    tenantId: bigint,
    periodStart: Date,
    periodEnd: Date,
    prisma: any = prismaCentralUnscoped as any,
  ): Promise<number> {
    return prisma.branch.count({
      where: {
        tenantId,
        active: true,
        createdAt: { lte: periodEnd },
        OR: [{ deletedAt: null }, { deletedAt: { gte: periodStart } }],
      },
    });
  }

  static calculateTotals(plan: PlanPricingInput, branchesUsed: number): BillingTotals {
    const totals = calculatePlanTotals(plan, branchesUsed);
    return {
      includedBranches: totals.includedBranches,
      extraBranches: totals.extraBranches,
      planMonthlyPriceCents: totals.monthlyPriceCents,
      extraBranchPriceCents: totals.extraBranchPriceCents,
      subtotalCents: totals.totalCents,
      totalCents: totals.totalCents,
    };
  }

  static calculateExtras(
    plan: PlanPricingInput,
    branchesUsed: number,
  ): { includedBranches: number; extraBranches: number } {
    const totals = this.calculateTotals(plan, branchesUsed);
    return {
      includedBranches: totals.includedBranches,
      extraBranches: totals.extraBranches,
    };
  }

  /**
   * Gera/actualiza BillingSnapshot + Invoice para um período.
   * Preserva preços no snapshot (imutável para histórico).
   */
  static async billSubscriptionPeriod(
    input: BillSubscriptionPeriodInput,
  ): Promise<BillSubscriptionPeriodResult> {
    const tx = input.tx;
    const tenantId = BigInt(input.subscription.tenantId);
    const subscriptionId = input.subscription.id;

    const branchesUsed =
      input.branchesUsedOverride != null
        ? Math.max(1, input.branchesUsedOverride)
        : await this.countActiveBranchesForPeriod(
            tenantId,
            input.periodStart,
            input.periodEnd,
            tx,
          );

    const totals = this.calculateTotals(input.subscription.plan, branchesUsed);
    const periodMonths = Math.max(1, Math.floor(Number(input.periodMonths ?? 1)));
    const scaledTotalCents = Math.round(totals.totalCents * periodMonths);
    const amountStr = fromCents(scaledTotalCents);

    await tx.subscription.update({
      where: { id: subscriptionId },
      data: { branchesUsed },
    });

    if (totals.totalCents <= 0) {
      if (!input.skipSubscriptionDateUpdate) {
        await this.updateSubscriptionBillingDates(tx, subscriptionId, {
          lastBillingAt: new Date(),
          nextBillingAt: addDaysUTC(input.periodEnd, 1),
          currentPeriodEnd: input.periodEnd,
        });
      }
      return {
        branchesUsed,
        includedBranches: totals.includedBranches,
        extraBranches: totals.extraBranches,
        subtotal: amountStr,
        total: amountStr,
        snapshotAction: "created",
        invoiceAction: "skipped_free",
      };
    }

    const upsert = input.upsertSnapshot !== false;
    let snapshotAction: "created" | "updated" = "created";
    let snapshot: any;

    if (upsert) {
      const existingSnapshot = await tx.billingSnapshot.findUnique({
        where: {
          subscriptionId_periodStart_periodEnd: {
            subscriptionId,
            periodStart: input.periodStart,
            periodEnd: input.periodEnd,
          },
        },
      });
      snapshotAction = existingSnapshot ? "updated" : "created";
      snapshot = await tx.billingSnapshot.upsert({
        where: {
          subscriptionId_periodStart_periodEnd: {
            subscriptionId,
            periodStart: input.periodStart,
            periodEnd: input.periodEnd,
          },
        },
        update: {
          planMonthlyPrice: fromCents(totals.planMonthlyPriceCents),
          includedBranches: totals.includedBranches,
          extraBranchesUsed: totals.extraBranches,
          extraBranchPrice: fromCents(totals.extraBranchPriceCents),
          totalBranchesUsed: branchesUsed,
          subtotal: amountStr,
          total: amountStr,
        },
        create: {
          tenantId,
          subscriptionId,
          periodStart: input.periodStart,
          periodEnd: input.periodEnd,
          planMonthlyPrice: fromCents(totals.planMonthlyPriceCents),
          includedBranches: totals.includedBranches,
          extraBranchesUsed: totals.extraBranches,
          extraBranchPrice: fromCents(totals.extraBranchPriceCents),
          totalBranchesUsed: branchesUsed,
          subtotal: amountStr,
          total: amountStr,
        },
      });
    } else {
      snapshot = await tx.billingSnapshot.create({
        data: {
          tenantId,
          subscriptionId,
          periodStart: input.periodStart,
          periodEnd: input.periodEnd,
          planMonthlyPrice: fromCents(totals.planMonthlyPriceCents),
          includedBranches: totals.includedBranches,
          extraBranchesUsed: totals.extraBranches,
          extraBranchPrice: fromCents(totals.extraBranchPriceCents),
          totalBranchesUsed: branchesUsed,
          subtotal: amountStr,
          total: amountStr,
        },
      });
    }

    const existingInvoice = await tx.invoice.findUnique({
      where: { billingSnapshotId: snapshot.id },
    });

    let invoiceAction: BillSubscriptionPeriodResult["invoiceAction"] = "created";
    let invoiceId: string | undefined;
    let invoiceNumber: string | undefined;

    if (existingInvoice?.status === "pago") {
      invoiceAction = "kept_paid";
      invoiceId = existingInvoice.id.toString();
      invoiceNumber = String(existingInvoice.number);
    } else if (existingInvoice) {
      const paid = Number(existingInvoice.paidAmount);
      const amount = Number(amountStr);
      const discount = Number(existingInvoice.discount ?? 0);
      assertInvoiceAmounts(amount, paid, discount);
      const status = deriveInvoiceStatus(
        amount,
        paid,
        String(existingInvoice.status),
        discount,
      );

      const updatedInvoice = await tx.invoice.update({
        where: { id: existingInvoice.id },
        data: {
          tenantId,
          subscriptionId,
          amount: amountStr,
          remainingAmount: computeRemainingAmount(amount, paid, discount),
          status,
          dueDate: input.dueDate,
          periodStart: input.periodStart,
          periodEnd: input.periodEnd,
          branchesUsed,
          extraBranches: totals.extraBranches,
          description: input.description,
        },
      });
      invoiceAction = "updated";
      invoiceId = updatedInvoice.id.toString();
      invoiceNumber = String(updatedInvoice.number);
    } else {
      const fiscal = await allocateInvoiceFiscal(
        tenantId,
        input.fiscalReferenceDate ?? input.periodStart,
        tx,
      );

      const createdInvoice = await tx.invoice.create({
        data: {
          tenantId,
          fiscalYear: fiscal.fiscalYear,
          sequence: fiscal.sequence,
          subscriptionId,
          billingSnapshotId: snapshot.id,
          number: fiscal.number,
          amount: amountStr,
          discount: 0,
          paidAmount: 0,
          remainingAmount: amountStr,
          status: "pendente",
          dueDate: input.dueDate,
          periodStart: input.periodStart,
          periodEnd: input.periodEnd,
          branchesUsed,
          extraBranches: totals.extraBranches,
          description: input.description,
        },
      });
      invoiceId = createdInvoice.id.toString();
      invoiceNumber = String(createdInvoice.number);
    }

    if (!input.skipSubscriptionDateUpdate && invoiceAction !== "kept_paid") {
      await this.updateSubscriptionBillingDates(tx, subscriptionId, {
        lastBillingAt: new Date(),
        nextBillingAt: addDaysUTC(input.periodEnd, 1),
        currentPeriodEnd: input.periodEnd,
      });
    }

    return {
      branchesUsed,
      includedBranches: totals.includedBranches,
      extraBranches: totals.extraBranches,
      subtotal: amountStr,
      total: amountStr,
      snapshotAction,
      invoiceAction,
      invoiceId,
      invoiceNumber,
      snapshotId: snapshot.id.toString(),
    };
  }

  static async updateSubscriptionBillingDates(
    tx: any,
    subscriptionId: bigint,
    data: {
      lastBillingAt?: Date | null;
      nextBillingAt?: Date | null;
      currentPeriodEnd?: Date | null;
    },
  ): Promise<void> {
    await tx.subscription.update({
      where: { id: subscriptionId },
      data,
    });
  }

  /** Preview sem escrita (dry-run). */
  static async previewPeriod(params: {
    tenantId: bigint;
    plan: PlanPricingInput;
    periodStart: Date;
    periodEnd: Date;
  }): Promise<BillingTotals & { branchesUsed: number }> {
    const branchesUsed = await this.countActiveBranchesForPeriod(
      params.tenantId,
      params.periodStart,
      params.periodEnd,
    );
    return {
      branchesUsed,
      ...this.calculateTotals(params.plan, branchesUsed),
    };
  }
}

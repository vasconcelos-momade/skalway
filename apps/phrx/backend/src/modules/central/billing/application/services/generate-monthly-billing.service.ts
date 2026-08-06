import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { EmailService } from "../../../../../infrastructure/notifications/email.service";
import { SubscriptionBillingService } from "./subscription-billing.service";
import {
  parseReferenceDate,
  startOfMonthUTC,
  endOfMonthUTC,
  addDaysUTC,
  fromCents,
  buildMonthlyInvoiceDescription,
} from "@skalway/billing";

export interface GenerateMonthlyBillingInput {
  referenceDate?: Date | string;
  tenantId?: string;
  subscriptionId?: string;
  dueDays?: number;
  dryRun?: boolean;
  includeTrial?: boolean;
}

export interface GeneratedBillingItem {
  tenantId: string;
  subscriptionId: string;
  planSlug: string;
  periodStart: string;
  periodEnd: string;
  dueDate: string;
  branchesUsed: number;
  includedBranches: number;
  extraBranches: number;
  subtotal: string;
  total: string;
  snapshotAction: "preview" | "created" | "updated";
  invoiceAction: "preview" | "created" | "updated" | "kept_paid" | "skipped_free";
  invoiceId?: string;
  invoiceNumber?: string;
  companyName?: string;
  tenantName?: string;
  ownerName?: string | null;
  ownerEmail?: string | null;
}

export interface GenerateMonthlyBillingResult {
  periodStart: string;
  periodEnd: string;
  dueDate: string;
  dryRun: boolean;
  processed: number;
  generated: number;
  updated: number;
  skipped: number;
  items: GeneratedBillingItem[];
}

/**
 * Orquestrador do job mensal — regras de selecção/skip;
 * cálculo e persistência via SubscriptionBillingService.
 */
export class GenerateMonthlyBillingService {
  async execute(input: GenerateMonthlyBillingInput = {}): Promise<GenerateMonthlyBillingResult> {
    const prisma = prismaCentralUnscoped as any;
    const referenceDate = parseReferenceDate(input.referenceDate);
    const periodStart = startOfMonthUTC(referenceDate);
    const periodEnd = endOfMonthUTC(referenceDate);
    const dueDate = addDaysUTC(periodEnd, input.dueDays ?? 3);
    const dryRun = Boolean(input.dryRun);
    const statuses = input.includeTrial ? ["trial", "ativo"] : ["ativo"];

    const subscriptions = await prisma.subscription.findMany({
      where: {
        status: { in: statuses },
        deletedAt: null,
        startDate: { lte: periodEnd },
        OR: [{ endDate: null }, { endDate: { gte: periodStart } }],
        ...(input.tenantId ? { tenantId: BigInt(input.tenantId) } : {}),
        ...(input.subscriptionId ? { id: BigInt(input.subscriptionId) } : {}),
      },
      include: {
        plan: true,
        tenant: {
          select: {
            id: true,
            tenantKey: true,
            tenantName: true,
            owner: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        },
      },
      orderBy: [{ tenantId: "asc" }, { createdAt: "asc" }],
    });

    const items: GeneratedBillingItem[] = [];
    let generated = 0;
    let updated = 0;
    let skipped = 0;

    for (const subscription of subscriptions) {
      if (!subscription.plan?.active) {
        skipped++;
        continue;
      }

      if (
        subscription.nextBillingAt &&
        new Date(subscription.nextBillingAt) > periodEnd
      ) {
        skipped++;
        continue;
      }

      if (subscription.autoRenew === false) {
        const next = subscription.nextBillingAt
          ? new Date(subscription.nextBillingAt)
          : null;
        if (next && (next < periodStart || next > periodEnd)) {
          skipped++;
          continue;
        }
      }

      const item = dryRun
        ? await this.previewSubscription({
            subscription,
            periodStart,
            periodEnd,
            dueDate,
          })
        : await this.persistSubscription({
            subscription,
            periodStart,
            periodEnd,
            dueDate,
          });

      if (item.invoiceAction === "created") generated++;
      if (item.invoiceAction === "updated") updated++;
      if (item.invoiceAction === "kept_paid" || item.invoiceAction === "skipped_free") {
        skipped++;
      }
      items.push(item);

      if (!dryRun && ["created", "updated"].includes(item.invoiceAction)) {
        await this.sendRecurringInvoiceEmail(item);
      }
    }

    return {
      periodStart: periodStart.toISOString(),
      periodEnd: periodEnd.toISOString(),
      dueDate: dueDate.toISOString(),
      dryRun,
      processed: subscriptions.length,
      generated,
      updated,
      skipped,
      items,
    };
  }

  private async previewSubscription(params: {
    subscription: any;
    periodStart: Date;
    periodEnd: Date;
    dueDate: Date;
  }): Promise<GeneratedBillingItem> {
    const preview = await SubscriptionBillingService.previewPeriod({
      tenantId: BigInt(params.subscription.tenantId),
      plan: params.subscription.plan,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    });

    return {
      tenantId: params.subscription.tenantId.toString(),
      subscriptionId: params.subscription.id.toString(),
      planSlug: String(params.subscription.plan.slug),
      periodStart: params.periodStart.toISOString(),
      periodEnd: params.periodEnd.toISOString(),
      dueDate: params.dueDate.toISOString(),
      branchesUsed: preview.branchesUsed,
      includedBranches: preview.includedBranches,
      extraBranches: preview.extraBranches,
      subtotal: fromCents(preview.subtotalCents),
      total: fromCents(preview.totalCents),
      snapshotAction: "preview",
      invoiceAction: "preview",
    };
  }

  private async persistSubscription(params: {
    subscription: any;
    periodStart: Date;
    periodEnd: Date;
    dueDate: Date;
  }): Promise<GeneratedBillingItem> {
    const prisma = prismaCentralUnscoped as any;

    return prisma.$transaction(async (tx: any) => {
      const branchesUsed = await SubscriptionBillingService.countActiveBranchesForPeriod(
        BigInt(params.subscription.tenantId),
        params.periodStart,
        params.periodEnd,
        tx,
      );
      const totals = SubscriptionBillingService.calculateTotals(
        params.subscription.plan,
        branchesUsed,
      );
      const description = buildMonthlyInvoiceDescription({
        planName: String(params.subscription.plan.name),
        planSlug: String(params.subscription.plan.slug),
        isEnterprise: Boolean(params.subscription.plan.isEnterprise),
        branchesUsed,
        includedBranches: totals.includedBranches,
        extraBranches: totals.extraBranches,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
      });

      const billed = await SubscriptionBillingService.billSubscriptionPeriod({
        tx,
        subscription: {
          id: params.subscription.id,
          tenantId: params.subscription.tenantId,
          plan: params.subscription.plan,
        },
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
        dueDate: params.dueDate,
        description,
        branchesUsedOverride: branchesUsed,
      });

      return {
        tenantId: params.subscription.tenantId.toString(),
        subscriptionId: params.subscription.id.toString(),
        planSlug: String(params.subscription.plan.slug),
        periodStart: params.periodStart.toISOString(),
        periodEnd: params.periodEnd.toISOString(),
        dueDate: params.dueDate.toISOString(),
        branchesUsed: billed.branchesUsed,
        includedBranches: billed.includedBranches,
        extraBranches: billed.extraBranches,
        subtotal: billed.subtotal,
        total: billed.total,
        snapshotAction: billed.snapshotAction,
        invoiceAction: billed.invoiceAction,
        invoiceId: billed.invoiceId,
        invoiceNumber: billed.invoiceNumber,
        tenantName: String(params.subscription.tenant.tenantName),
        ownerName: params.subscription.tenant.owner?.name
          ? String(params.subscription.tenant.owner.name)
          : null,
        ownerEmail: params.subscription.tenant.owner?.email
          ? String(params.subscription.tenant.owner.email)
          : null,
      } satisfies GeneratedBillingItem;
    });
  }

  private async sendRecurringInvoiceEmail(item: GeneratedBillingItem): Promise<void> {
    if (!item.ownerEmail || !item.tenantName || !item.invoiceNumber) return;

    await EmailService.send({
      to: item.ownerEmail,
      subject: `Factura emitida para ${item.tenantName}`,
      text: [
        `Foi emitida a factura ${item.invoiceNumber} para o tenant ${item.tenantName}.`,
        `Valor: ${item.total} MZN.`,
        item.extraBranches > 0
          ? `Inclui ${item.extraBranches} filial(is) adicional(is).`
          : undefined,
        `Periodo faturado: ${item.periodStart.slice(0, 10)} a ${item.periodEnd.slice(0, 10)}.`,
        `Prazo limite de pagamento: ${item.dueDate.slice(0, 10)}.`,
        item.ownerName ? `Responsavel: ${item.ownerName}.` : undefined,
        "Se nao houver pagamento ate ao vencimento, o tenant sera suspenso automaticamente.",
      ]
        .filter(Boolean)
        .join("\n"),
    });
  }
}

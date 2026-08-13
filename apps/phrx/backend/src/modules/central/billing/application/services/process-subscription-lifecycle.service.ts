import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { EmailService } from "../../../../../infrastructure/notifications/email.service";
import {
  parseReferenceDate,
  addDaysUTC,
} from "@skalway/billing";

export interface ProcessSubscriptionLifecycleInput {
  referenceDate?: Date | string;
}

export interface ProcessSubscriptionLifecycleResult {
  referenceDate: string;
  freeTrialsActivated: number;
  invoicesMarkedOverdue: number;
  tenantsSuspended: number;
  subscriptionsCancelled: number;
}

/**
 * Lifecycle SaaS:
 * - Fatura do trial é criada na criação do tenant (não aqui).
 * - Fim do trial sem pagamento → fatura vencida + tenant suspenso (via overdue).
 * - Planos gratuitos em trial → activação automática no fim do trial.
 * - 30 dias após vencido → subscrição cancelada.
 */
export class ProcessSubscriptionLifecycleService {
  async execute(
    input: ProcessSubscriptionLifecycleInput = {},
  ): Promise<ProcessSubscriptionLifecycleResult> {
    const prisma = prismaCentralUnscoped as any;
    const referenceDate = parseReferenceDate(input.referenceDate);

    let freeTrialsActivated = 0;

    const expiredTrials = await prisma.subscription.findMany({
      where: {
        status: "trial",
        deletedAt: null,
        trialEndsAt: { lte: referenceDate },
        tenant: { deletedAt: null },
      },
      include: {
        plan: true,
        invoices: {
          where: {
            deletedAt: null,
            status: { in: ["pendente", "parcial", "pago"] },
          },
          orderBy: { createdAt: "asc" },
          take: 5,
        },
      },
      orderBy: { trialEndsAt: "asc" },
    });

    for (const subscription of expiredTrials) {
      const activated = await this.processExpiredTrial(subscription.id, referenceDate);
      if (activated) freeTrialsActivated++;
    }

    const overdueInvoices = await prisma.invoice.findMany({
      where: {
        deletedAt: null,
        status: { in: ["pendente", "parcial"] },
        dueDate: { lt: referenceDate },
        tenant: { deletedAt: null },
      },
      orderBy: { dueDate: "asc" },
      select: { id: true },
    });

    let invoicesMarkedOverdue = 0;
    let tenantsSuspended = 0;

    for (const invoice of overdueInvoices) {
      const result = await this.processOverdueInvoice(invoice.id, referenceDate);
      if (!result) continue;

      invoicesMarkedOverdue++;
      tenantsSuspended++;
      await this.sendSuspensionEmail(result);
    }

    const cancelAfter = addDaysUTC(referenceDate, -30);
    const cancellationCandidates = await prisma.invoice.findMany({
      where: {
        deletedAt: null,
        status: "vencido",
        dueDate: { lte: cancelAfter },
        tenant: { deletedAt: null },
        subscription: {
          deletedAt: null,
          status: { not: "cancelado" },
        },
      },
      orderBy: { dueDate: "asc" },
      select: { id: true },
    });

    let subscriptionsCancelled = 0;

    for (const invoice of cancellationCandidates) {
      const result = await this.processCancelledSubscription(invoice.id, referenceDate);
      if (!result) continue;

      subscriptionsCancelled++;
      await this.sendCancellationEmail(result);
    }

    return {
      referenceDate: referenceDate.toISOString(),
      freeTrialsActivated,
      invoicesMarkedOverdue,
      tenantsSuspended,
      subscriptionsCancelled,
    };
  }

  /**
   * No fim do trial:
   * - Se já pago → já deveria estar `ativo` (confirm payment).
   * - Se plano gratuito (sem fatura pendente) → activar.
   * - Se fatura pendente → deixa o processOverdueInvoice suspender.
   */
  private async processExpiredTrial(
    subscriptionId: bigint,
    referenceDate: Date,
  ): Promise<boolean> {
    const prisma = prismaCentralUnscoped as any;

    return prisma.$transaction(async (tx: any) => {
      const subscription = await tx.subscription.findUnique({
        where: { id: subscriptionId },
        include: {
          plan: true,
          invoices: {
            where: {
              deletedAt: null,
              status: { in: ["pendente", "parcial"] },
            },
            take: 1,
          },
        },
      });

      if (
        !subscription ||
        subscription.deletedAt ||
        subscription.status !== "trial" ||
        !subscription.trialEndsAt ||
        subscription.trialEndsAt > referenceDate
      ) {
        return false;
      }

      const hasOpenInvoice = (subscription.invoices?.length ?? 0) > 0;
      const isFreePlan =
        Boolean(subscription.plan?.isEnterprise) ||
        Number(subscription.plan?.monthlyPrice ?? 0) <= 0;

      if (hasOpenInvoice) {
        // Fatura já existe desde a criação — o overdue trata suspensão.
        return false;
      }

      if (!isFreePlan) {
        return false;
      }

      await tx.subscription.update({
        where: { id: subscription.id },
        data: {
          status: "ativo",
          lastBillingAt: referenceDate,
          nextBillingAt: null,
          currentPeriodEnd: null,
        },
      });

      await tx.tenant.update({
        where: { id: subscription.tenantId },
        data: { status: "ativo" },
      });

      return true;
    });
  }

  private async processOverdueInvoice(invoiceId: bigint, referenceDate: Date) {
    const prisma = prismaCentralUnscoped as any;

    return prisma.$transaction(async (tx: any) => {
      const invoice = await tx.invoice.findUnique({
        where: { id: invoiceId },
        include: {
          tenant: {
            select: {
              tenantName: true,
              owner: {
                select: {
                  name: true,
                  email: true,
                },
              },
            },
          },
          subscription: {
            select: {
              id: true,
              status: true,
            },
          },
        },
      });

      if (
        !invoice ||
        invoice.deletedAt ||
        !["pendente", "parcial"].includes(String(invoice.status)) ||
        invoice.dueDate >= referenceDate
      ) {
        return null;
      }

      await tx.invoice.update({
        where: { id: invoice.id },
        data: {
          status: "vencido",
        },
      });

      await tx.subscription.update({
        where: { id: invoice.subscriptionId },
        data: {
          status: "expirado",
          nextBillingAt: null,
        },
      });

      await tx.tenant.update({
        where: { id: invoice.tenantId },
        data: {
          status: "suspenso",
        },
      });

      return {
        tenantName: String(invoice.tenant.tenantName),
        ownerName: invoice.tenant.owner?.name ? String(invoice.tenant.owner.name) : null,
        ownerEmail: invoice.tenant.owner?.email ? String(invoice.tenant.owner.email) : null,
        invoiceNumber: String(invoice.number),
        dueDate: invoice.dueDate,
        amount: String(invoice.amount),
      };
    });
  }

  private async processCancelledSubscription(invoiceId: bigint, referenceDate: Date) {
    const prisma = prismaCentralUnscoped as any;

    return prisma.$transaction(async (tx: any) => {
      const invoice = await tx.invoice.findUnique({
        where: { id: invoiceId },
        include: {
          tenant: {
            select: {
              tenantName: true,
              owner: {
                select: {
                  name: true,
                  email: true,
                },
              },
            },
          },
          subscription: {
            select: {
              id: true,
              status: true,
            },
          },
        },
      });

      if (
        !invoice ||
        invoice.deletedAt ||
        String(invoice.status) !== "vencido" ||
        String(invoice.subscription?.status) === "cancelado" ||
        addDaysUTC(invoice.dueDate, 30) > referenceDate
      ) {
        return null;
      }

      await tx.subscription.update({
        where: { id: invoice.subscriptionId },
        data: {
          status: "cancelado",
          endDate: referenceDate,
          nextBillingAt: null,
        },
      });

      return {
        tenantName: String(invoice.tenant.tenantName),
        ownerName: invoice.tenant.owner?.name ? String(invoice.tenant.owner.name) : null,
        ownerEmail: invoice.tenant.owner?.email ? String(invoice.tenant.owner.email) : null,
        invoiceNumber: String(invoice.number),
        dueDate: invoice.dueDate,
        amount: String(invoice.amount),
      };
    });
  }

  private async sendSuspensionEmail(payload: {
    tenantName: string;
    ownerName: string | null;
    ownerEmail: string | null;
    invoiceNumber: string;
    dueDate: Date;
    amount: string;
  }) {
    if (!payload.ownerEmail) return;

    await EmailService.send({
      to: payload.ownerEmail,
      subject: `Tenant suspenso por falta de pagamento: ${payload.tenantName}`,
      text: [
        `A factura ${payload.invoiceNumber} do tenant ${payload.tenantName} venceu sem pagamento.`,
        `Valor pendente: ${payload.amount} MZN.`,
        `Data limite: ${payload.dueDate.toISOString().slice(0, 10)}.`,
        payload.ownerName ? `Responsavel: ${payload.ownerName}.` : undefined,
        "O tenant foi suspenso ate regularizacao financeira.",
      ]
        .filter(Boolean)
        .join("\n"),
    });
  }

  private async sendCancellationEmail(payload: {
    tenantName: string;
    ownerName: string | null;
    ownerEmail: string | null;
    invoiceNumber: string;
    dueDate: Date;
    amount: string;
  }) {
    if (!payload.ownerEmail) return;

    await EmailService.send({
      to: payload.ownerEmail,
      subject: `Subscricao cancelada por falta de pagamento: ${payload.tenantName}`,
      text: [
        `A factura ${payload.invoiceNumber} do tenant ${payload.tenantName} permanece sem pagamento ha mais de 30 dias.`,
        `Valor pendente: ${payload.amount} MZN.`,
        `Vencimento original: ${payload.dueDate.toISOString().slice(0, 10)}.`,
        payload.ownerName ? `Responsavel: ${payload.ownerName}.` : undefined,
        "A subscricao foi cancelada. Para reactivar o tenant sera necessario regularizar a conta e activar uma nova subscricao.",
      ]
        .filter(Boolean)
        .join("\n"),
    });
  }
}

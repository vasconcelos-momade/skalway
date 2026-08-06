import { PaymentMethod } from "../../../../../infrastructure/prisma/central/generated/central";
import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import { addDaysUTC } from "@skalway/billing";
import { writeCentralAuditLog } from "../../../infrastructure/central-audit.helper";

export interface CreditWalletDTO {
  tenantId: string;
  amount: number;
  months: number;
  method: PaymentMethod | string;
  reference?: string;
  notes?: string | null;
  userId?: string | null;
}

const PAYMENT_METHODS = new Set<string>(Object.values(PaymentMethod));

function parsePaymentMethod(input: string): PaymentMethod {
  const normalized = input.trim().toUpperCase();
  if (!PAYMENT_METHODS.has(normalized)) {
    throw new Error(`Método de pagamento inválido: ${input}`);
  }
  return normalized as PaymentMethod;
}

function addMonthsUTC(date: Date, months: number): Date {
  const result = new Date(date.getTime());
  result.setUTCMonth(result.getUTCMonth() + months);
  return result;
}

/**
 * Crédito de carteira + extensão de cobertura da subscrição (pagamento antecipado).
 * Não gera fatura — o saldo fica disponível e o período coberto avança N meses.
 */
export class CreditWalletUseCase {
  async execute(data: CreditWalletDTO) {
    if (!Number.isFinite(data.amount) || data.amount <= 0) {
      throw new Error("amount deve ser um valor positivo.");
    }
    if (!Number.isInteger(data.months) || data.months < 1 || data.months > 36) {
      throw new Error("months deve ser um inteiro entre 1 e 36.");
    }

    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const tenantId = BigInt(data.tenantId);
      const method = parsePaymentMethod(String(data.method));
      const userId = data.userId ? BigInt(data.userId) : null;
      const reference =
        data.reference?.trim() ||
        (method === PaymentMethod.CASH
          ? `CASH-WALLET-${data.tenantId}-${Date.now()}`
          : "");
      if (!reference) {
        throw new Error("reference é obrigatório excepto para CASH.");
      }

      return prisma.$transaction(async (tx: any) => {
        const tenant = await tx.tenant.findFirst({
          where: { id: tenantId, deletedAt: null },
          select: { id: true, companyName: true, name: true },
        });
        if (!tenant) {
          throw new Error("Tenant não encontrado.");
        }

        const existingPayment = await tx.payment.findFirst({
          where: {
            tenantId,
            reference,
            deletedAt: null,
          },
        });
        if (existingPayment) {
          throw new Error("Já existe um pagamento com esta referência.");
        }

        const subscription = await tx.subscription.findFirst({
          where: {
            tenantId,
            status: { in: ["trial", "ativo", "expirado", "grace"] },
            deletedAt: null,
          },
          include: { plan: true },
          orderBy: { createdAt: "desc" },
        });
        if (!subscription) {
          throw new Error("Tenant sem subscrição activa.");
        }

        const now = new Date();
        const coverageStart =
          subscription.currentPeriodEnd &&
          new Date(subscription.currentPeriodEnd) > now
            ? new Date(subscription.currentPeriodEnd)
            : now;
        const coverageEnd = addMonthsUTC(coverageStart, data.months);
        // coversTo é o último dia coberto (um dia antes do próximo ciclo).
        const coversTo = addDaysUTC(coverageEnd, -1);
        const nextBillingAt = coverageEnd;

        const payment = await tx.payment.create({
          data: {
            tenantId,
            invoiceId: null,
            amount: data.amount,
            method,
            reference,
            notes:
              data.notes?.trim() ||
              `Crédito antecipado — ${data.months} mês(es)`,
            status: "confirmado",
            confirmedAt: now,
            confirmedBy: userId,
            createdBy: userId,
            updatedBy: userId,
            coversFrom: coverageStart,
            coversTo,
            monthsCovered: data.months,
          },
        });

        const wallet = await tx.tenantWallet.upsert({
          where: { tenantId },
          create: {
            tenantId,
            balance: data.amount,
          },
          update: {
            balance: { increment: data.amount },
            deletedAt: null,
          },
        });

        const balanceAfter = Number(wallet.balance);

        await tx.walletTransaction.create({
          data: {
            tenantId,
            paymentId: payment.id,
            type: "CREDIT",
            amount: data.amount,
            balanceAfter,
            description:
              data.notes?.trim() ||
              `Crédito antecipado (${data.months} mês(es)) — ${reference}`,
          },
        });

        await tx.subscription.update({
          where: { id: subscription.id },
          data: {
            status: "ativo",
            currentPeriodEnd:
              !subscription.currentPeriodEnd ||
              coversTo > new Date(subscription.currentPeriodEnd)
                ? coversTo
                : subscription.currentPeriodEnd,
            nextBillingAt:
              !subscription.nextBillingAt ||
              nextBillingAt > new Date(subscription.nextBillingAt)
                ? nextBillingAt
                : subscription.nextBillingAt,
            lastBillingAt: now,
          },
        });

        await tx.tenant.update({
          where: { id: tenantId },
          data: { status: "ativo" },
        });

        await writeCentralAuditLog(
          {
            tenantId,
            userId,
            action: "WALLET_CREDIT",
            entity: "TenantWallet",
            entityId: wallet.id.toString(),
            newData: {
              amount: data.amount,
              months: data.months,
              balanceAfter,
              paymentId: payment.id.toString(),
              reference,
              coversFrom: coverageStart.toISOString(),
              coversTo: coversTo.toISOString(),
            },
          },
          tx,
        );

        return {
          wallet: {
            tenantId: tenantId.toString(),
            balance: balanceAfter,
          },
          payment: {
            id: payment.id.toString(),
            amount: data.amount,
            method,
            reference,
            monthsCovered: data.months,
            coversFrom: coverageStart,
            coversTo,
            status: "confirmado",
          },
          subscription: {
            id: subscription.id.toString(),
            currentPeriodEnd: coversTo,
            nextBillingAt,
          },
        };
      });
    });
  }
}

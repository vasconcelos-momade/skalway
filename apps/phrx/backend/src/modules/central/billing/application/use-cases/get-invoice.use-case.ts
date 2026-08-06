import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import {
  DEFAULT_INVOICE_CURRENCY,
  mapInvoiceFinancialFields,
} from "../services/invoice-response.mapper";

export interface GetInvoiceDTO {
  tenantId: string;
  invoiceId: string;
}

export class GetInvoiceUseCase {
  async execute(data: GetInvoiceDTO) {
    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const invoice = await prisma.invoice.findFirst({
        where: {
          id: BigInt(data.invoiceId),
          tenantId: BigInt(data.tenantId),
          deletedAt: null,
        },
        include: {
          tenant: {
            select: {
              tenantKey: true,
              tenantName: true,
              nuit: true,
              email: true,
              endereco: true,
            },
          },
          billingSnapshot: {
            select: {
              planMonthlyPrice: true,
              includedBranches: true,
              extraBranchesUsed: true,
              extraBranchPrice: true,
              totalBranchesUsed: true,
              subtotal: true,
              total: true,
            },
          },
          subscription: {
            select: {
              plan: { select: { name: true, slug: true } },
            },
          },
          payments: {
            where: { deletedAt: null },
            select: {
              id: true,
              amount: true,
              method: true,
              status: true,
              reference: true,
              proofUrl: true,
              confirmedAt: true,
              createdAt: true,
            },
            orderBy: { createdAt: "desc" },
          },
        },
      });

      if (!invoice) {
        throw new Error("Fatura não encontrada.");
      }

      const financials = mapInvoiceFinancialFields(invoice);
      const snapshot = invoice.billingSnapshot;
      const periodStart = invoice.periodStart
        ? new Date(invoice.periodStart).toISOString().slice(0, 10)
        : null;
      const periodEnd = invoice.periodEnd
        ? new Date(invoice.periodEnd).toISOString().slice(0, 10)
        : null;

      return {
        id: invoice.id.toString(),
        subscriptionId: invoice.subscriptionId.toString(),
        number: invoice.number,
        ...financials,
        currency: DEFAULT_INVOICE_CURRENCY,
        status: invoice.status,
        dueDate: invoice.dueDate,
        paidAt: invoice.paidAt,
        periodStart: invoice.periodStart,
        periodEnd: invoice.periodEnd,
        period:
          periodStart && periodEnd ? `${periodStart} a ${periodEnd}` : null,
        branchesUsed: invoice.branchesUsed,
        extraBranches: invoice.extraBranches,
        description: invoice.description,
        planName: invoice.subscription?.plan?.name ?? null,
        planSlug: invoice.subscription?.plan?.slug ?? null,
        planMonthlyPrice: snapshot ? Number(snapshot.planMonthlyPrice) : null,
        includedBranches: snapshot?.includedBranches ?? null,
        extraBranchPrice: snapshot ? Number(snapshot.extraBranchPrice) : null,
        snapshotExtraBranches: snapshot?.extraBranchesUsed ?? null,
        snapshotTotalBranches: snapshot?.totalBranchesUsed ?? null,
        subtotal: snapshot ? Number(snapshot.subtotal) : financials.amount,
        createdAt: invoice.createdAt,
        tenant: invoice.tenant
          ? {
              tenantKey: invoice.tenant.tenantKey,
              tenantName: invoice.tenant.tenantName,
              nuit: invoice.tenant.nuit,
              contact: invoice.tenant.email,
              address: invoice.tenant.endereco,
            }
          : null,
        payments: invoice.payments.map((payment: any) => ({
          id: payment.id.toString(),
          amount: payment.amount,
          currency: DEFAULT_INVOICE_CURRENCY,
          method: payment.method,
          status: payment.status,
          reference: payment.reference,
          proofUrl: payment.proofUrl,
          confirmedAt: payment.confirmedAt,
          createdAt: payment.createdAt,
        })),
      };
    });
  }
}

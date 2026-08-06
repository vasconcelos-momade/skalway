import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import {
  DEFAULT_INVOICE_CURRENCY,
  mapInvoiceFinancialFields,
} from "../services/invoice-response.mapper";

export interface ListTenantInvoicesDTO {
  tenantId: string;
  status?: string;
  limit?: number;
}

export class ListTenantInvoicesUseCase {
  async execute(data: ListTenantInvoicesDTO) {
    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const limit = Math.min(Math.max(data.limit ?? 50, 1), 100);

      const invoices = await prisma.invoice.findMany({
        where: {
          tenantId: BigInt(data.tenantId),
          deletedAt: null,
          ...(data.status ? { status: data.status } : {}),
        },
        select: {
          id: true,
          number: true,
          amount: true,
          discount: true,
          paidAmount: true,
          remainingAmount: true,
          status: true,
          dueDate: true,
          paidAt: true,
          periodStart: true,
          periodEnd: true,
          branchesUsed: true,
          extraBranches: true,
          description: true,
          subscriptionId: true,
          createdAt: true,
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
        },
        orderBy: { createdAt: "desc" },
        take: limit,
      });

      return invoices.map((invoice: any) => {
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
          planMonthlyPrice: snapshot
            ? Number(snapshot.planMonthlyPrice)
            : null,
          includedBranches: snapshot?.includedBranches ?? null,
          extraBranchPrice: snapshot
            ? Number(snapshot.extraBranchPrice)
            : null,
          snapshotExtraBranches: snapshot?.extraBranchesUsed ?? null,
          snapshotTotalBranches: snapshot?.totalBranchesUsed ?? null,
          subtotal: snapshot ? Number(snapshot.subtotal) : financials.amount,
          createdAt: invoice.createdAt,
        };
      });
    });
  }
}

import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import {
  DEFAULT_INVOICE_CURRENCY,
  mapInvoiceFinancialFields,
} from "../services/invoice-response.mapper";

export interface ListCentralInvoicesDTO {
  page?: number;
  pageSize?: number;
  q?: string;
  status?: string;
  tenantIds?: string[];
}

export type ListCentralInvoicesResult = {
  items: Array<Record<string, unknown>>;
  page: number;
  pageSize: number;
  hasMore: boolean;
  totalCount: number;
};

/**
 * Lista global de faturas SaaS (Central), com paginação server-side.
 */
export class ListCentralInvoicesUseCase {
  async execute(data: ListCentralInvoicesDTO): Promise<ListCentralInvoicesResult> {
    const prisma = prismaCentralUnscoped as any;
    const page = Math.max(1, data.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, data.pageSize ?? 20));
    const search = data.q?.trim();

    const where: Record<string, unknown> = {
      deletedAt: null,
      ...(data.status ? { status: data.status } : {}),
      ...(data.tenantIds?.length
        ? { tenantId: { in: data.tenantIds.map((id) => BigInt(id)) } }
        : {}),
      ...(search
        ? {
            OR: [
              { number: { contains: search } },
              { description: { contains: search } },
              { tenant: { name: { contains: search } } },
              { tenant: { companyName: { contains: search } } },
            ],
          }
        : {}),
    };

    const [totalCount, rows] = await prisma.$transaction([
      prisma.invoice.count({ where }),
      prisma.invoice.findMany({
        where,
        select: {
          id: true,
          tenantId: true,
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
          tenant: {
            select: {
              id: true,
              name: true,
              companyName: true,
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
        },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);

    const slice = rows.slice(0, pageSize);
    const items = slice.map((invoice: any) => {
      const financials = mapInvoiceFinancialFields(invoice);
      const snapshot = invoice.billingSnapshot;
      const periodStart = invoice.periodStart
        ? new Date(invoice.periodStart).toISOString().slice(0, 10)
        : null;
      const periodEnd = invoice.periodEnd
        ? new Date(invoice.periodEnd).toISOString().slice(0, 10)
        : null;
      const extras =
        snapshot?.extraBranchesUsed ?? invoice.extraBranches ?? 0;
      const extraPrice = snapshot ? Number(snapshot.extraBranchPrice) : null;
      const extrasAmount =
        extraPrice != null ? Math.round(extras * extraPrice * 100) / 100 : null;

      return {
        id: invoice.id.toString(),
        tenantId: invoice.tenantId.toString(),
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
        tenantName: invoice.tenant?.name ?? null,
        companyName: invoice.tenant?.companyName ?? null,
        planName: invoice.subscription?.plan?.name ?? null,
        planSlug: invoice.subscription?.plan?.slug ?? null,
        planMonthlyPrice: snapshot ? Number(snapshot.planMonthlyPrice) : null,
        includedBranches: snapshot?.includedBranches ?? null,
        extraBranchPrice: extraPrice,
        extrasAmount,
        snapshotExtraBranches: snapshot?.extraBranchesUsed ?? null,
        snapshotTotalBranches: snapshot?.totalBranchesUsed ?? null,
        subtotal: snapshot ? Number(snapshot.subtotal) : financials.amount,
        createdAt: invoice.createdAt,
      };
    });

    return {
      items,
      page,
      pageSize,
      hasMore: rows.length > pageSize,
      totalCount,
    };
  }
}

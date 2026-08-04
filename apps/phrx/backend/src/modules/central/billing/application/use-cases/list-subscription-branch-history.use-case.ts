import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";

export interface ListSubscriptionBranchHistoryDTO {
  tenantId: string;
  limit?: number;
}

export class ListSubscriptionBranchHistoryUseCase {
  async execute(data: ListSubscriptionBranchHistoryDTO) {
    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const limit = Math.min(Math.max(data.limit ?? 50, 1), 100);
      const tenantId = BigInt(data.tenantId);

      const subscription = await prisma.subscription.findFirst({
        where: { tenantId, deletedAt: null },
        orderBy: { createdAt: "desc" },
        select: { id: true },
      });

      if (!subscription) {
        return [];
      }

      const rows = await prisma.subscriptionBranchHistory.findMany({
        where: { subscriptionId: subscription.id },
        include: {
          branch: {
            select: { id: true, code: true, name: true, isHeadOffice: true },
          },
          createdByUser: {
            select: { id: true, name: true, email: true },
          },
        },
        orderBy: { effectiveDate: "desc" },
        take: limit,
      });

      return rows.map((row: any) => ({
        id: row.id.toString(),
        subscriptionId: row.subscriptionId.toString(),
        branchId: row.branchId.toString(),
        branchCode: row.branch?.code ?? null,
        branchName: row.branch?.name ?? null,
        isHeadOffice: Boolean(row.branch?.isHeadOffice),
        action: row.action,
        effectiveDate: row.effectiveDate,
        reason: row.reason,
        createdAt: row.createdAt,
        createdBy: row.createdBy ? row.createdBy.toString() : null,
        createdByName: row.createdByUser?.name ?? null,
        createdByEmail: row.createdByUser?.email ?? null,
      }));
    });
  }
}

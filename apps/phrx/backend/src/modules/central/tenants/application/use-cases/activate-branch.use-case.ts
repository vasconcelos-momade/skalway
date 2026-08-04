import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import { SubscriptionBranchHistoryService } from "../../../billing/application/services/subscription-branch-history.service";

export interface ActivateBranchDTO {
  tenantId: string;
  branchId: string;
  reason?: string | null;
  userId?: string | null;
}

/**
 * Reactiva uma filial previamente desactivada.
 * Não gera fatura imediata — extras entram na próxima cobrança.
 */
export class ActivateBranchUseCase {
  async execute(data: ActivateBranchDTO) {
    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const tenantId = BigInt(data.tenantId);
      const branchId = BigInt(data.branchId);

      return prisma.$transaction(async (tx: any) => {
        const branch = await tx.branch.findFirst({
          where: { id: branchId, tenantId, deletedAt: null },
        });

        if (!branch) {
          throw new Error("Filial não encontrada.");
        }

        if (branch.active) {
          return {
            id: branch.id.toString(),
            code: branch.code,
            name: branch.name,
            active: true,
            alreadyActive: true,
          };
        }

        const subscription = await tx.subscription.findFirst({
          where: {
            tenantId,
            status: { in: ["trial", "ativo", "expirado"] },
            deletedAt: null,
          },
          include: { plan: true },
          orderBy: { createdAt: "desc" },
        });

        if (!subscription) {
          throw new Error("Tenant sem subscrição para actualizar o cache de filiais.");
        }

        const updated = await tx.branch.update({
          where: { id: branchId },
          data: {
            active: true,
            updatedBy: data.userId ? BigInt(data.userId) : null,
          },
        });

        const history = await SubscriptionBranchHistoryService.recordBranchAdd({
          tx,
          tenantId,
          subscriptionId: subscription.id,
          branchId,
          createdBy: data.userId ? BigInt(data.userId) : null,
          includedBranches: Number(subscription.plan?.includedBranches ?? 1),
          branchCode: updated.code,
          branchName: updated.name,
          reason: data.reason ?? "Filial activada — incluída na próxima cobrança",
        });

        return {
          id: updated.id.toString(),
          code: updated.code,
          name: updated.name,
          active: true,
          branchesUsed: history.branchesUsed,
          extraBranches: history.extraBranches,
          includedBranches: history.includedBranches,
        };
      });
    });
  }
}

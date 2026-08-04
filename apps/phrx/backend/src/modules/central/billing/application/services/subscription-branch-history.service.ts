import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { writeCentralAuditLog } from "../../../infrastructure/central-audit.helper";
import { SubscriptionBillingService } from "./subscription-billing.service";

export type BranchHistoryAction = "ADD" | "REMOVE";

export interface RecordBranchChangeInput {
  tx: any;
  tenantId: bigint;
  subscriptionId: bigint;
  branchId: bigint;
  action: BranchHistoryAction;
  reason?: string | null;
  createdBy?: bigint | null;
  /** Código/nome da branch para auditoria. */
  branchCode?: string | null;
  branchName?: string | null;
  includedBranches?: number;
}

export interface RecordBranchChangeResult {
  branchesUsed: number;
  extraBranches: number;
  includedBranches: number;
}

/**
 * Regista ADD/REMOVE de filiais na subscrição:
 * - SubscriptionBranchHistory (auditoria / futura pró-rata)
 * - actualiza cache Subscription.branchesUsed
 * - AuditLog central
 *
 * Não gera fatura — cobrança de extras fica para o próximo ciclo.
 */
export class SubscriptionBranchHistoryService {
  static async recordBranchChange(
    input: RecordBranchChangeInput,
  ): Promise<RecordBranchChangeResult> {
    const tx = input.tx;
    const effectiveDate = new Date();

    await tx.subscriptionBranchHistory.create({
      data: {
        subscriptionId: input.subscriptionId,
        branchId: input.branchId,
        action: input.action,
        effectiveDate,
        reason: input.reason ?? null,
        createdBy: input.createdBy ?? null,
      },
    });

    const branchesUsed = await SubscriptionBillingService.countActiveBranches(
      input.tenantId,
      tx,
    );

    await tx.subscription.update({
      where: { id: input.subscriptionId },
      data: { branchesUsed },
    });

    const subscription = await tx.subscription.findUnique({
      where: { id: input.subscriptionId },
      include: { plan: true },
    });
    const includedBranches = Number(
      input.includedBranches ?? subscription?.plan?.includedBranches ?? 1,
    );
    const extras = SubscriptionBillingService.calculateExtras(
      subscription?.plan ?? { includedBranches, isEnterprise: false },
      branchesUsed,
    );

    await writeCentralAuditLog(
      {
        tenantId: input.tenantId,
        branchId: input.branchId,
        userId: input.createdBy ?? null,
        action: input.action === "ADD" ? "BRANCH_ADD" : "BRANCH_REMOVE",
        entity: "SubscriptionBranchHistory",
        entityId: input.branchId.toString(),
        newData: {
          subscriptionId: input.subscriptionId.toString(),
          branchId: input.branchId.toString(),
          branchCode: input.branchCode ?? null,
          branchName: input.branchName ?? null,
          action: input.action,
          branchesUsed,
          includedBranches,
          extraBranches: extras.extraBranches,
          reason: input.reason ?? null,
          effectiveDate: effectiveDate.toISOString(),
        },
      },
      tx,
    );

    return {
      branchesUsed,
      extraBranches: extras.extraBranches,
      includedBranches,
    };
  }

  /** Convenience: regista ADD e actualiza cache. */
  static async recordBranchAdd(
    input: Omit<RecordBranchChangeInput, "action">,
  ): Promise<RecordBranchChangeResult> {
    return this.recordBranchChange({ ...input, action: "ADD" });
  }

  /** Convenience: regista REMOVE e actualiza cache. */
  static async recordBranchRemove(
    input: Omit<RecordBranchChangeInput, "action">,
  ): Promise<RecordBranchChangeResult> {
    return this.recordBranchChange({ ...input, action: "REMOVE" });
  }
}

/** Contagem directa (fora de transacção) para leituras. */
export async function countTenantActiveBranches(tenantId: bigint): Promise<number> {
  return SubscriptionBillingService.countActiveBranches(
    tenantId,
    prismaCentralUnscoped as any,
  );
}

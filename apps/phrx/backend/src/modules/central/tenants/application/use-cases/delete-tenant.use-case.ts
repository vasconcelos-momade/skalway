import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { MySqlManagementService } from "../../../../../infrastructure/database/mysql-management.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import { writeCentralAuditLog } from "../../../infrastructure/central-audit.helper";
import { serializeForJson } from "../../../../../shared/http/serialize-json";
import {
  ConflictApiError,
  NotFoundApiError,
} from "../../../../../shared/http/api-error";

export interface DeleteTenantInput {
  tenantId: string;
  userId: string;
}

type BranchSnapshot = {
  id: string;
  name: string;
  code: string;
  dbName: string;
  active: boolean;
};

type SoftDeleteStep = {
  model: string;
  count: number;
};

/**
 * Eliminação de Tenant (Central soft-delete operacional → DROP das BDs isoladas).
 *
 * Ordem: validar → soft-delete operacional na Central → revogar sessões →
 * auditoria → DROP DATABASE.
 *
 * Idempotente: se o Tenant já tem deletedAt, retoma o DROP das BDs pendentes.
 *
 * Preservados (sem soft-delete / sem apagar):
 * Invoice, Payment, WalletTransaction, TenantWallet, BillingSnapshot,
 * InvoiceFiscalCounter, SubscriptionBranchHistory, AuditLog, UserSession (só revoke).
 *
 * Soft-delete operacional: Tenant, Branch, UserTenant, User (se sem outros tenants),
 * UserPermission, Subscription (cancelada), Settings, Devices, Printers, Sync, Jobs.
 */
export class DeleteTenantUseCase {
  async execute(data: DeleteTenantInput) {
    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const tenantId = BigInt(data.tenantId);
      const actorId = BigInt(data.userId);
      const startedAt = new Date();

      const tenant = await prisma.tenant.findUnique({
        where: { id: tenantId },
        select: {
          id: true,
          tenantName: true,
          tenantKey: true,
          ownerUserId: true,
          status: true,
          deletedAt: true,
          branches: {
            select: {
              id: true,
              name: true,
              code: true,
              dbName: true,
              active: true,
              deletedAt: true,
            },
          },
          payments: {
            where: { deletedAt: null, status: "pendente" },
            select: { id: true },
            take: 1,
          },
          userTenants: {
            where: { deletedAt: null },
            select: { userId: true },
          },
        },
      });

      if (!tenant) {
        throw new NotFoundApiError("Tenant não encontrado.");
      }

      const alreadySoftDeleted = tenant.deletedAt != null;

      if (!alreadySoftDeleted && (tenant.payments?.length ?? 0) > 0) {
        throw new ConflictApiError(
          "Não é possível eliminar o tenant enquanto existirem pagamentos pendentes de confirmação.",
        );
      }

      const branchSnapshots: BranchSnapshot[] = (tenant.branches ?? []).map(
        (b: {
          id: bigint;
          name: string;
          code: string;
          dbName: string;
          active: boolean;
        }) => ({
          id: b.id.toString(),
          name: b.name,
          code: b.code,
          dbName: b.dbName,
          active: b.active,
        }),
      );

      const memberUserIds: bigint[] = Array.from(
        new Set(
          (tenant.userTenants ?? []).map((ut: { userId: bigint }) => ut.userId),
        ),
      );
      if (
        tenant.ownerUserId != null &&
        !memberUserIds.some((id) => id === tenant.ownerUserId)
      ) {
        memberUserIds.push(tenant.ownerUserId);
      }

      await writeCentralAuditLog({
        tenantId,
        userId: actorId,
        action: "TENANT_DELETE_STARTED",
        entity: "Tenant",
        entityId: data.tenantId,
        data: serializeForJson({
          alreadySoftDeleted,
          tenantName: tenant.tenantName,
          tenantKey: tenant.tenantKey,
          branches: branchSnapshots,
          memberUserCount: memberUserIds.length,
          startedAt: startedAt.toISOString(),
        }),
      });

      let softDeleteSteps: SoftDeleteStep[] = [];
      let deletedKey = tenant.tenantKey as string;
      const softDeletedAt = alreadySoftDeleted
        ? (tenant.deletedAt as Date)
        : new Date();

      try {
        if (!alreadySoftDeleted) {
          deletedKey = tenant.tenantKey.includes("_deleted_")
            ? tenant.tenantKey
            : `${tenant.tenantKey}_deleted_${tenant.id}_${softDeletedAt.getTime()}`;

          softDeleteSteps = await prisma.$transaction(async (tx: any) => {
            const steps: SoftDeleteStep[] = [];

            const softDelete = async (
              model: string,
              result: { count: number },
            ) => {
              steps.push({ model, count: result.count });
            };

            // Subscrição: cancelar (operacional). Histórico de facturas/pagamentos fica intacto.
            await softDelete(
              "Subscription",
              await tx.subscription.updateMany({
                where: { tenantId, deletedAt: null },
                data: {
                  deletedAt: softDeletedAt,
                  updatedBy: actorId,
                  status: "cancelado",
                },
              }),
            );

            await softDelete(
              "BranchSetting",
              await tx.branchSetting.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt },
              }),
            );

            await softDelete(
              "TenantSetting",
              await tx.tenantSetting.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt },
              }),
            );

            await softDelete(
              "PrintJob",
              await tx.printJob.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt },
              }),
            );

            await softDelete(
              "Printer",
              await tx.printer.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt },
              }),
            );

            await softDelete(
              "Device",
              await tx.device.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt },
              }),
            );

            await softDelete(
              "SyncLog",
              await tx.syncLog.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt },
              }),
            );

            await softDelete(
              "SyncSession",
              await tx.syncSession.updateMany({
                where: { tenantId, deletedAt: null },
                data: {
                  deletedAt: softDeletedAt,
                  endedAt: softDeletedAt,
                },
              }),
            );

            await softDelete(
              "JobQueue",
              await tx.jobQueue.updateMany({
                where: {
                  tenantId,
                  deletedAt: null,
                  status: { in: ["PENDING", "PROCESSING"] },
                },
                data: {
                  deletedAt: softDeletedAt,
                  status: "CANCELLED",
                  lastError: "Tenant eliminado",
                },
              }),
            );

            await softDelete(
              "UserPermission",
              await tx.userPermission.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt },
              }),
            );

            // Revogar sessões activas dos membros (histórico de sessão permanece).
            if (memberUserIds.length > 0) {
              await softDelete(
                "UserSession",
                await tx.userSession.updateMany({
                  where: {
                    userId: { in: memberUserIds },
                    revokedAt: null,
                  },
                  data: {
                    revokedAt: softDeletedAt,
                    revokedReason: "Tenant eliminado",
                  },
                }),
              );
            }

            await softDelete(
              "UserTenant",
              await tx.userTenant.updateMany({
                where: { tenantId, deletedAt: null },
                data: { deletedAt: softDeletedAt, active: false },
              }),
            );

            // Soft-delete de Users que ficam sem qualquer membership activa
            // (nunca superadmin nem o actor da operação).
            let usersSoftDeleted = 0;
            for (const userId of memberUserIds) {
              if (userId === actorId) continue;

              const user = await tx.user.findFirst({
                where: { id: userId, deletedAt: null },
                select: { id: true, role: true },
              });
              if (!user || user.role === "superadmin") continue;

              const otherMembership = await tx.userTenant.findFirst({
                where: {
                  userId,
                  deletedAt: null,
                  active: true,
                  tenantId: { not: tenantId },
                },
                select: { id: true },
              });
              if (otherMembership) continue;

              await tx.user.update({
                where: { id: userId },
                data: {
                  deletedAt: softDeletedAt,
                  active: false,
                },
              });
              usersSoftDeleted += 1;
            }
            steps.push({ model: "User", count: usersSoftDeleted });

            await softDelete(
              "Branch",
              await tx.branch.updateMany({
                where: { tenantId, deletedAt: null },
                data: {
                  deletedAt: softDeletedAt,
                  active: false,
                  updatedBy: actorId,
                },
              }),
            );

            await tx.tenant.update({
              where: { id: tenantId },
              data: {
                deletedAt: softDeletedAt,
                updatedBy: actorId,
                tenantKey: deletedKey,
                status: "suspenso",
              },
            });
            steps.push({ model: "Tenant", count: 1 });

            await writeCentralAuditLog(
              {
                tenantId,
                userId: actorId,
                action: "TENANT_DELETE_CENTRAL_SOFT_DELETE",
                entity: "Tenant",
                entityId: data.tenantId,
                oldData: serializeForJson({
                  tenantName: tenant.tenantName,
                  tenantKey: tenant.tenantKey,
                  status: tenant.status,
                  branches: branchSnapshots,
                }),
                newData: serializeForJson({
                  deletedAt: softDeletedAt.toISOString(),
                  tenantKey: deletedKey,
                  status: "suspenso",
                  steps,
                  preservedHistorical: [
                    "Invoice",
                    "Payment",
                    "WalletTransaction",
                    "TenantWallet",
                    "BillingSnapshot",
                    "InvoiceFiscalCounter",
                    "SubscriptionBranchHistory",
                    "AuditLog",
                    "UserSession (revoked only)",
                  ],
                }),
              },
              tx,
            );

            return steps;
          });
        }

        const dropped: string[] = [];
        const alreadyAbsent: string[] = [];
        const dropErrors: Array<{ dbName: string; error: string }> = [];

        for (const branch of branchSnapshots) {
          const dbName = String(branch.dbName ?? "").trim();
          if (!dbName || dbName.startsWith("__")) continue;
          try {
            const result = await MySqlManagementService.dropDatabase(dbName);
            if (result.dropped) {
              dropped.push(dbName);
            } else {
              alreadyAbsent.push(dbName);
            }
          } catch (error) {
            dropErrors.push({
              dbName,
              error: error instanceof Error ? error.message : String(error),
            });
          }
        }

        await writeCentralAuditLog({
          tenantId,
          userId: actorId,
          action:
            dropErrors.length > 0
              ? "TENANT_DELETE_DB_DROP_PARTIAL"
              : "TENANT_DELETE_DB_DROP",
          entity: "Tenant",
          entityId: data.tenantId,
          data: serializeForJson({
            dropped,
            alreadyAbsent,
            dropErrors,
          }),
        });

        if (dropErrors.length > 0) {
          await writeCentralAuditLog({
            tenantId,
            userId: actorId,
            action: "TENANT_DELETE_FAILED",
            entity: "Tenant",
            entityId: data.tenantId,
            data: serializeForJson({
              stage: "DROP_DATABASE",
              softDeletedAt: softDeletedAt.toISOString(),
              softDeleteSteps,
              dropErrors,
            }),
          });
          console.error(
            `[DeleteTenant] Tenant ${data.tenantId} soft-deleted; falhas ao dropar BD:`,
            dropErrors,
          );
          throw new Error(
            `Dados históricos preservados na Central, mas falhou a remoção de ${dropErrors.length} base(s): ${dropErrors
              .map((e) => e.dbName)
              .join(", ")}. Pode repetir a eliminação para retomar o DROP.`,
          );
        }

        await writeCentralAuditLog({
          tenantId,
          userId: actorId,
          action: "TENANT_DELETE_COMPLETED",
          entity: "Tenant",
          entityId: data.tenantId,
          data: serializeForJson({
            tenantName: tenant.tenantName,
            tenantKey: deletedKey,
            softDeletedAt: softDeletedAt.toISOString(),
            resumed: alreadySoftDeleted,
            softDeleteSteps,
            databasesDropped: dropped,
            databasesAlreadyAbsent: alreadyAbsent,
            completedAt: new Date().toISOString(),
          }),
        });

        return {
          message: alreadySoftDeleted
            ? "Eliminação retomada: bases das filiais removidas com sucesso"
            : "Tenant eliminado: histórico financeiro preservado na Central e bases das filiais removidas",
          tenantId: data.tenantId,
          resumed: alreadySoftDeleted,
          softDeleteSteps,
          databasesDropped: dropped,
          databasesAlreadyAbsent: alreadyAbsent,
        };
      } catch (error) {
        if (
          error instanceof ConflictApiError ||
          error instanceof NotFoundApiError
        ) {
          throw error;
        }

        const message =
          error instanceof Error ? error.message : String(error);

        if (!message.includes("falhou a remoção")) {
          await writeCentralAuditLog({
            tenantId,
            userId: actorId,
            action: "TENANT_DELETE_FAILED",
            entity: "Tenant",
            entityId: data.tenantId,
            data: serializeForJson({
              stage: alreadySoftDeleted ? "RESUME" : "CENTRAL_SOFT_DELETE",
              error: message,
            }),
          }).catch(() => undefined);
        }

        throw error;
      }
    });
  }
}

import { prismaCentral } from "../../../../../infrastructure/prisma/prisma-central.service";
import { MySqlManagementService } from "../../../../../infrastructure/database/mysql-management.service";
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

/**
 * Soft-delete do tenant no Central + DROP das bases MySQL de todas as filiais.
 */
export class DeleteTenantUseCase {
  async execute(data: DeleteTenantInput) {
    const prisma = prismaCentral as any;
    const tenantId = BigInt(data.tenantId);
    const actorId = BigInt(data.userId);

    const tenant = await prisma.tenant.findFirst({
      where: { id: tenantId, deletedAt: null },
      select: {
        id: true,
        tenantName: true,
        tenantKey: true,
        ownerUserId: true,
        branches: {
          where: { deletedAt: null },
          select: {
            id: true,
            name: true,
            code: true,
            dbName: true,
            active: true,
          },
        },
        subscriptions: {
          where: { deletedAt: null },
          select: { id: true, status: true },
        },
        invoices: {
          where: { status: "pago" },
          select: { id: true },
          take: 1,
        },
      },
    });

    if (!tenant) {
      throw new NotFoundApiError("Tenant não encontrado.");
    }

    const hasActivePaidSub = (tenant.subscriptions ?? []).some(
      (s: { status?: string | null }) =>
        String(s.status ?? "").toLowerCase() === "ativo",
    );
    if (hasActivePaidSub) {
      throw new ConflictApiError(
        "Não é possível eliminar um tenant com plano pago activo.",
      );
    }

    if ((tenant.invoices?.length ?? 0) > 0) {
      throw new ConflictApiError(
        "Não é possível eliminar um tenant que possui facturas pagas.",
      );
    }

    const now = new Date();
    const deletedKey = `${tenant.tenantKey}_deleted_${tenant.id}_${now.getTime()}`;
    const branchSnapshots = (tenant.branches ?? []).map(
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

    await prisma.$transaction(async (tx: any) => {
      await tx.subscription.updateMany({
        where: { tenantId, deletedAt: null },
        data: { deletedAt: now, updatedBy: actorId, status: "cancelado" },
      });

      await tx.branch.updateMany({
        where: { tenantId, deletedAt: null },
        data: {
          deletedAt: now,
          active: false,
          updatedBy: actorId,
        },
      });

      await tx.userTenant.updateMany({
        where: { tenantId, deletedAt: null },
        data: { deletedAt: now, active: false },
      });

      await tx.device.updateMany({
        where: { tenantId, deletedAt: null },
        data: { deletedAt: now },
      }).catch(() => undefined);

      await tx.tenant.update({
        where: { id: tenantId },
        data: {
          deletedAt: now,
          updatedBy: actorId,
          tenantKey: deletedKey,
          status: "suspenso",
        },
      });

      await writeCentralAuditLog(
        {
          tenantId,
          userId: actorId,
          action: "TENANT_DELETE",
          entity: "Tenant",
          entityId: data.tenantId,
          oldData: serializeForJson({
            tenantName: tenant.tenantName,
            tenantKey: tenant.tenantKey,
            branches: branchSnapshots,
          }),
          newData: serializeForJson({
            deletedAt: now.toISOString(),
            tenantKey: deletedKey,
            databasesDropped: branchSnapshots.map(
              (b: { dbName: string }) => b.dbName,
            ),
          }),
        },
        tx,
      );
    });

    const dropped: string[] = [];
    const dropErrors: Array<{ dbName: string; error: string }> = [];

    for (const branch of branchSnapshots) {
      const dbName = String(branch.dbName ?? "").trim();
      if (!dbName || dbName.startsWith("__")) continue;
      try {
        await MySqlManagementService.dropDatabase(dbName);
        dropped.push(dbName);
      } catch (error) {
        dropErrors.push({
          dbName,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }

    if (dropErrors.length > 0) {
      console.error(
        `[DeleteTenant] Tenant ${data.tenantId} soft-deleted; falhas ao dropar BD:`,
        dropErrors,
      );
      throw new Error(
        `Tenant eliminado no Central, mas falhou a remoção de ${dropErrors.length} base(s): ${dropErrors
          .map((e) => e.dbName)
          .join(", ")}`,
      );
    }

    return {
      message: "Tenant e bases das filiais eliminados com sucesso",
      tenantId: data.tenantId,
      databasesDropped: dropped,
    };
  }
}

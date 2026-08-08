import { MySqlManagementService } from "../../../../../infrastructure/database/mysql-management.service";
import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { TenantPrismaFactory } from "../../../../../infrastructure/prisma/tenant-prisma.factory";
import { assertTenantBillingActive } from "../../../billing/application/services/tenant-billing-guard.service";
import { branchContext } from "../../../../../shared/context/branch-context";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import { EmailService } from "../../../../../infrastructure/notifications/email.service";
import { generateBranchCode } from "../../domain/generate-branch-code";
import {
  BRANCH_DB_NAME_PENDING,
  buildBranchDbName,
} from "../../domain/branch-db-name";
import { SubscriptionBranchHistoryService } from "../../../billing/application/services/subscription-branch-history.service";
import { PrinterService } from "../../../printer/application/services/printer.service";
import { BranchSettingService } from "../../../branch-settings/application/services/branch-setting.service";

export interface CreateBranchDTO {
  tenantId: string;
  name: string;
}

async function cloneHqUsersToBranch(params: {
  tenantId: string;
  hqBranchId: string;
  hqDbName: string;
  hqDbHost: string;
  hqDbPort: number;
  hqDbUsername: string;
  hqDbPasswordCipherText: string;
  hqDbPasswordIv: string;
  hqDbPasswordTag?: string | null;
  branchId: string;
  branchDbName: string;
  branchDbHost: string;
  branchDbPort: number;
  branchDbUsername: string;
  branchDbPasswordCipherText: string;
  branchDbPasswordIv: string;
  branchDbPasswordTag?: string | null;
}) {
  const hqUsers = await branchContext.run(
    {
      tenantId: params.tenantId,
      branchId: params.hqBranchId,
      dbName: params.hqDbName,
      dbHost: params.hqDbHost,
      dbPort: params.hqDbPort,
      dbUsername: params.hqDbUsername,
      dbPasswordCipherText: params.hqDbPasswordCipherText,
      dbPasswordIv: params.hqDbPasswordIv,
      dbPasswordTag: params.hqDbPasswordTag,
    },
    async () => {
      const prismaTenant = TenantPrismaFactory.getClient() as any;
      return prismaTenant.user.findMany({
        where: { deletedAt: null },
        select: {
          name: true,
          email: true,
          role: true,
          active: true,
          centralUserId: true,
          userPermissions: {
            select: {
              module: true,
              action: true,
              allowed: true,
            },
          },
        },
      });
    },
  );

  if (hqUsers.length === 0) {
    return 0;
  }

  return branchContext.run(
    {
      tenantId: params.tenantId,
      branchId: params.branchId,
      dbName: params.branchDbName,
      dbHost: params.branchDbHost,
      dbPort: params.branchDbPort,
      dbUsername: params.branchDbUsername,
      dbPasswordCipherText: params.branchDbPasswordCipherText,
      dbPasswordIv: params.branchDbPasswordIv,
      dbPasswordTag: params.branchDbPasswordTag,
    },
    async () => {
      const prismaTenant = TenantPrismaFactory.getClient() as any;

      await prismaTenant.user.createMany({
        data: hqUsers.map((user: any) => ({
          name: user.name,
          email: user.email,
          role: user.role,
          active: user.active,
          centralUserId: user.centralUserId,
        })),
        skipDuplicates: true,
      });

      const branchUsers = await prismaTenant.user.findMany({
        select: {
          id: true,
          email: true,
          centralUserId: true,
        },
      });

      const branchUserByCentralId = new Map<string, any>();
      const branchUserByEmail = new Map<string, any>();

      for (const user of branchUsers) {
        if (user.centralUserId !== null && user.centralUserId !== undefined) {
          branchUserByCentralId.set(String(user.centralUserId), user);
        }
        if (user.email) {
          branchUserByEmail.set(String(user.email).toLowerCase(), user);
        }
      }

      const permissionRows = hqUsers.flatMap((user: any) => {
        const targetUser =
          (user.centralUserId !== null && user.centralUserId !== undefined
            ? branchUserByCentralId.get(String(user.centralUserId))
            : undefined) ??
          (user.email
            ? branchUserByEmail.get(String(user.email).toLowerCase())
            : undefined);

        if (!targetUser || !user.userPermissions?.length) {
          return [];
        }

        return user.userPermissions.map((permission: any) => ({
          userId: targetUser.id,
          module: permission.module,
          action: permission.action,
          allowed: permission.allowed,
        }));
      });

      if (permissionRows.length > 0) {
        await prismaTenant.userPermission.createMany({
          data: permissionRows,
          skipDuplicates: true,
        });
      }

      return prismaTenant.user.count();
    },
  );
}

export class CreateBranchUseCase {
  async execute(data: CreateBranchDTO) {
    await assertTenantBillingActive(data.tenantId);

    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const tenantId = BigInt(data.tenantId);
      const branchCode = generateBranchCode();

      const setup = await prisma.$transaction(async (tx: any) => {
        const subscription = await tx.subscription.findFirst({
          where: {
            tenantId,
            status: { in: ["trial", "ativo"] },
          },
          include: { plan: true },
          orderBy: { createdAt: "desc" },
        });

        if (!subscription) {
          throw new Error("Tenant não possui assinatura ativa.");
        }

        if (!subscription.plan?.active) {
          throw new Error("O plano atual do tenant está inativo.");
        }

        const hqBranch = await tx.branch.findFirst({
          where: { tenantId, isHeadOffice: true },
        });

        if (!hqBranch) {
          throw new Error("Matriz não encontrada para o tenant.");
        }

        const tenant = await tx.tenant.findUnique({
          where: { id: tenantId },
          select: {
            tenantName: true,
            nuit: true,
            email: true,
            endereco: true,
            owner: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        });

        const createdBranch = await tx.branch.create({
          data: {
            tenantId,
            code: branchCode,
            name: data.name,
            isHeadOffice: false,
            active: true,
            dbHost: hqBranch.dbHost,
            dbPort: hqBranch.dbPort,
            dbName: BRANCH_DB_NAME_PENDING,
            dbUsername: hqBranch.dbUsername,
            dbPasswordCipherText: hqBranch.dbPasswordCipherText,
            dbPasswordIv: hqBranch.dbPasswordIv,
            dbPasswordTag: hqBranch.dbPasswordTag,
          },
        });

        const dbName = buildBranchDbName(tenantId, createdBranch.id);
        const branch = await tx.branch.update({
          where: { id: createdBranch.id },
          data: { dbName },
        });

        await new PrinterService().createDefaultPrinter({
          tx,
          tenantId,
          branchId: branch.id,
        });

        await new BranchSettingService().seedDefaults({
          tx,
          tenantId,
          branchId: branch.id,
          defaults: {
            branchName: branch.name,
            branchCode: branch.code,
            nomeLegal: branch.name,
          },
        });

        const history = await SubscriptionBranchHistoryService.recordBranchAdd({
          tx,
          tenantId,
          subscriptionId: subscription.id,
          branchId: branch.id,
          includedBranches: Number(subscription.plan?.includedBranches ?? 1),
          branchCode: branch.code,
          branchName: branch.name,
          reason: "Criação de filial adicional — cobrança no próximo ciclo",
        });

        return {
          branch,
          dbName,
          hqBranchId: hqBranch.id,
          dbHost: hqBranch.dbHost,
          dbPort: hqBranch.dbPort,
          hqDbName: hqBranch.dbName,
          dbUsername: hqBranch.dbUsername,
          dbPasswordCipherText: hqBranch.dbPasswordCipherText,
          dbPasswordIv: hqBranch.dbPasswordIv,
          dbPasswordTag: hqBranch.dbPasswordTag,
          includedBranches: Number(subscription.plan?.includedBranches ?? 1),
          branchesUsed: history.branchesUsed,
          extraBranches: history.extraBranches,
          tenant,
        };
      });

      await MySqlManagementService.createDatabase(setup.dbName);
      MySqlManagementService.runMigrations(setup.dbName);
      MySqlManagementService.runStructuralSeed(setup.dbName);

      const copiedUsers = await cloneHqUsersToBranch({
        tenantId: data.tenantId,
        hqBranchId: String(setup.hqBranchId),
        hqDbName: setup.hqDbName,
        hqDbHost: setup.dbHost,
        hqDbPort: setup.dbPort,
        hqDbUsername: setup.dbUsername,
        hqDbPasswordCipherText: setup.dbPasswordCipherText,
        hqDbPasswordIv: setup.dbPasswordIv,
        hqDbPasswordTag: setup.dbPasswordTag,
        branchId: setup.branch.id.toString(),
        branchDbName: setup.dbName,
        branchDbHost: setup.dbHost,
        branchDbPort: setup.dbPort,
        branchDbUsername: setup.dbUsername,
        branchDbPasswordCipherText: setup.dbPasswordCipherText,
        branchDbPasswordIv: setup.dbPasswordIv,
        branchDbPasswordTag: setup.dbPasswordTag,
      });

      const ownerEmail = setup.tenant?.owner?.email;
      if (ownerEmail) {
        const extrasNote =
          setup.extraBranches > 0
            ? `Filiais extras a cobrar no proximo ciclo: ${setup.extraBranches} (${setup.extraBranches} x preco extra do plano).`
            : "Ainda dentro do limite de filiais incluidas no plano.";
        await EmailService.send({
          to: ownerEmail,
          subject: `Nova branch criada para ${setup.tenant.tenantName}`,
          text: [
            `A branch ${setup.branch.name} (${setup.branch.code}) foi criada com sucesso.`,
            `Base de dados dedicada: ${setup.dbName}.`,
            `Utilizadores copiados da matriz: ${copiedUsers}.`,
            `Branches activas actuais: ${setup.branchesUsed}.`,
            `Incluidas no plano actual: ${setup.includedBranches}.`,
            extrasNote,
            "Nao ha cobranca imediata — o valor sera reflectido na proxima factura.",
          ].join("\n"),
        });
      }

      return {
        id: setup.branch.id.toString(),
        code: setup.branch.code,
        name: setup.branch.name,
        dbName: setup.dbName,
        branchesUsed: setup.branchesUsed,
        extraBranches: setup.extraBranches,
        includedBranches: setup.includedBranches,
      };
    });
  }
}

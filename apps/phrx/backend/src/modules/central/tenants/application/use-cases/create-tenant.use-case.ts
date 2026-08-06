import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { MySqlManagementService } from "../../../../../infrastructure/database/mysql-management.service";
import { syncTenantUsersFromCentral } from "../../../../../infrastructure/database/sync-tenant-users.service";
import { TenantPrismaFactory } from "../../../../../infrastructure/prisma/tenant-prisma.factory";
import { branchContext } from "../../../../../shared/context/branch-context";
import { encryptTenantDbPassword } from "../../../../../infrastructure/security/tenant-db-credentials";
import { EmailService } from "../../../../../infrastructure/notifications/email.service";
import { generateBranchCode } from "../../domain/generate-branch-code";
import { createTrialInvoice } from "../../../billing/application/services/create-trial-invoice.service";
import { SubscriptionBranchHistoryService } from "../../../billing/application/services/subscription-branch-history.service";
import { addDaysUTC } from "@skalway/billing";

export interface CreateTenantDTO {
  /** Nome visível do tenant. */
  tenantName: string;
  /**
   * Identificador técnico. Se omitido, é gerado a partir de tenantName.
   * A UI não envia este campo — apenas o backend gera.
   */
  tenantKey?: string | null;
  adminName: string;
  adminEmail: string;
  adminPassword: string;
  userId: string;
  email?: string | null;
  endereco?: string | null;
  nuit?: string | null;
  telefone?: string | null;
  planSlug?: string | null;
  status?: "trial" | "ativo" | null;
  /** Nome da branch inicial (default = tenantName). */
  branchName?: string | null;
}

/** @deprecated Use CreateTenantDTO */
export type RegisterTenantDTO = CreateTenantDTO;

const runtimeGlobals = globalThis as typeof globalThis & {
  process?: {
    env?: Record<string, string | undefined>;
  };
  console?: {
    log: (...args: unknown[]) => void;
  };
};

export function normalizeTenantSlug(raw: string): string {
  return raw
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 48);
}

/** NUIT moçambicano: 9 dígitos. */
export function isValidNuit(nuit: string): boolean {
  return /^\d{9}$/.test(nuit.replace(/\s+/g, ""));
}

export class CreateTenantUseCase {
  async execute(data: CreateTenantDTO) {
    const prisma = prismaCentralUnscoped as any;
    const tenantName = data.tenantName.trim();
    if (!tenantName) {
      throw new Error("Nome do tenant é obrigatório.");
    }

    const slug = normalizeTenantSlug(data.tenantKey?.trim() || tenantName);
    if (!slug || slug.length < 2) {
      throw new Error(
        "Não foi possível gerar tenantKey a partir do nome. Use letras e números.",
      );
    }

    const nuitRaw = data.nuit?.trim() || null;
    if (nuitRaw && !isValidNuit(nuitRaw)) {
      throw new Error("NUIT inválido. Deve conter exactamente 9 dígitos.");
    }
    const nuit = nuitRaw ? nuitRaw.replace(/\s+/g, "") : null;

    const dbName = `tenant_${slug}`;
    const adminEmail = data.adminEmail.trim().toLowerCase();
    const dbPasswordPlain = runtimeGlobals.process?.env?.MYSQL_ROOT_PASSWORD;
    if (!dbPasswordPlain) {
      throw new Error("MYSQL_ROOT_PASSWORD não definido.");
    }
    const { cipherText, iv, tag } = encryptTenantDbPassword(dbPasswordPlain);
    const dbHost = runtimeGlobals.process?.env?.MYSQL_HOST || "phrx-db";
    const dbPort = Number(runtimeGlobals.process?.env?.MYSQL_PORT || 3306);

    const planSlug = (data.planSlug?.trim() || "starter").toLowerCase();
    const tenantStatus = data.status === "ativo" ? "ativo" : "trial";
    const branchCode = generateBranchCode();
    const branchName = data.branchName?.trim() || tenantName;

    runtimeGlobals.console?.log(`🚀 [CreateTenant] Iniciando: ${slug}`);

    // Libertar tenantKey se existir apenas soft-deleted (@@unique global).
    const existingByKey = await prisma.tenant.findUnique({
      where: { tenantKey: slug },
    });
    if (existingByKey && !existingByKey.deletedAt) {
      throw new Error(`Já existe um tenant com o identificador "${slug}".`);
    }
    if (existingByKey?.deletedAt) {
      await prisma.tenant.update({
        where: { id: existingByKey.id },
        data: { tenantKey: `${slug}_deleted_${existingByKey.id}` },
      });
    }

    const plan =
      (await prisma.plan.findFirst({
        where: { slug: planSlug, active: true, deletedAt: null },
      })) ??
      (await prisma.plan.findFirst({
        where: { slug: "starter", active: true, deletedAt: null },
      }));

    if (!plan) {
      throw new Error(
        "Nenhum plano padrão foi encontrado. Rode o bootstrap:central antes de criar tenants.",
      );
    }

    const startDate = new Date();
    const trialDays = Math.max(1, Number(plan.trialDays ?? 14));
    const trialEndsAt = addDaysUTC(startDate, trialDays);
    const subscriptionStatus = tenantStatus === "ativo" ? "ativo" : "trial";

    runtimeGlobals.console?.log(`📝 [CreateTenant] 1/6 Registo central (transação)...`);

    const { tenant, branch, subscription } = await prisma.$transaction(async (tx: any) => {
      const tenant = await tx.tenant.create({
        data: {
          tenantName,
          tenantKey: slug,
          ownerUserId: BigInt(data.userId),
          status: tenantStatus,
          email: data.email?.trim() || null,
          endereco: data.endereco?.trim() || null,
          nuit,
          country: "MZ",
          createdBy: BigInt(data.userId),
          updatedBy: BigInt(data.userId),
        },
      });

      const settings: Array<{ tenantId: bigint; key: string; value: unknown }> = [
        { tenantId: tenant.id, key: "language", value: "pt" },
      ];
      if (data.telefone?.trim()) {
        settings.push({ tenantId: tenant.id, key: "telefone", value: data.telefone.trim() });
      }
      await tx.tenantSetting.createMany({ data: settings });

      const allPermissions = await tx.permission.findMany();
      if (allPermissions.length > 0) {
        await tx.userPermission.createMany({
          data: allPermissions.map((p: any) => ({
            userId: BigInt(data.userId),
            permissionId: p.id,
            tenantId: tenant.id,
            allowed: true,
          })),
        });
      }

      await tx.userTenant.create({
        data: {
          userId: BigInt(data.userId),
          tenantId: tenant.id,
          role: "ADMIN",
          active: true,
        },
      });

      const subscription = await tx.subscription.create({
        data: {
          tenantId: tenant.id,
          planId: plan.id,
          branchesUsed: 1,
          status: subscriptionStatus,
          startDate,
          trialEndsAt: subscriptionStatus === "trial" ? trialEndsAt : null,
          currentPeriodEnd: subscriptionStatus === "trial" ? trialEndsAt : null,
          nextBillingAt: subscriptionStatus === "trial" ? trialEndsAt : startDate,
          createdBy: BigInt(data.userId),
          updatedBy: BigInt(data.userId),
        },
      });

      if (subscriptionStatus === "trial") {
        const invoice = await createTrialInvoice({
          tx,
          tenantId: tenant.id,
          subscriptionId: subscription.id,
          plan,
          startDate,
          trialEndsAt,
          branchesUsed: 1,
        });
        if (invoice) {
          runtimeGlobals.console?.log(
            `🧾 [CreateTenant] Fatura trial ${invoice.invoiceNumber} (${invoice.amount} MZN) venc. ${invoice.dueDate.toISOString().slice(0, 10)}`,
          );
        }
      }

      runtimeGlobals.console?.log(`🏢 [CreateTenant] 2/6 Branch principal (${branchCode})...`);
      const branch = await tx.branch.create({
        data: {
          tenantId: tenant.id,
          code: branchCode,
          name: branchName,
          isHeadOffice: true,
          active: true,
          dbHost,
          dbPort,
          dbName,
          dbUsername: "root",
          dbPasswordCipherText: cipherText,
          dbPasswordIv: iv,
          dbPasswordTag: tag,
          createdBy: BigInt(data.userId),
          updatedBy: BigInt(data.userId),
        },
      });

      await SubscriptionBranchHistoryService.recordBranchAdd({
        tx,
        tenantId: tenant.id,
        subscriptionId: subscription.id,
        branchId: branch.id,
        createdBy: BigInt(data.userId),
        includedBranches: Number(plan.includedBranches ?? 1),
        branchCode: branch.code,
        branchName: branch.name,
        reason: "Filial Matriz criada com o tenant",
      });

      return { tenant, branch, subscription };
    });

    try {
      runtimeGlobals.console?.log(`🛠  [CreateTenant] 3/6 Criar base de dados ${dbName}...`);
      await MySqlManagementService.createDatabase(dbName);

      runtimeGlobals.console?.log(`⚙️  [CreateTenant] 4/6 Migrations do tenant...`);
      MySqlManagementService.runMigrations(dbName);

      runtimeGlobals.console?.log(`🔐 [CreateTenant] 5/6 Seeders estruturais...`);
      MySqlManagementService.runStructuralSeed(dbName);

      runtimeGlobals.console?.log(`👤 [CreateTenant] 6/6 Sincronizar utilizadores...`);
      const centralForAdmin = await prisma.user.findUnique({
        where: { email: adminEmail },
        select: { id: true, name: true, email: true },
      });
      const ownerCentral = await prisma.user.findUnique({
        where: { id: BigInt(data.userId) },
        select: { id: true, name: true, email: true },
      });

      const tenantUserCount = await branchContext.run(
        {
          tenantId: tenant.id.toString(),
          branchId: branch.id.toString(),
          dbName,
          dbHost,
          dbPort,
          dbUsername: "root",
          dbPasswordCipherText: cipherText,
          dbPasswordIv: iv,
          dbPasswordTag: tag,
        },
        async () => {
          const prismaTenant = TenantPrismaFactory.getClient();
          return syncTenantUsersFromCentral({
            tenantId: tenant.id,
            prismaTenant,
            extraUsers: [
              {
                name: data.adminName,
                email: adminEmail,
                centralUserId: centralForAdmin?.id ?? null,
              },
            ],
          });
        },
      );

      runtimeGlobals.console?.log(
        `👤 ${tenantUserCount} utilizador(es) tenant sincronizados em ${dbName}.`,
      );

      const notificationEmail = ownerCentral?.email ?? adminEmail;
      const notificationName = ownerCentral?.name ?? data.adminName;

      try {
        await EmailService.send({
          to: notificationEmail,
          subject: `Cliente criado: ${tenantName}`,
          text: [
            `O tenant ${tenantName} foi criado com sucesso.`,
            `Identificador: ${slug}.`,
            `Plano: ${plan.name}.`,
            `Estado: ${tenantStatus}.`,
            subscriptionStatus === "trial"
              ? `Trial válido até ${trialEndsAt.toISOString().slice(0, 10)}.`
              : "Subscrição activa.",
            `Branch inicial: ${branch.name} (${branch.code}).`,
            `Responsável registado: ${notificationName}.`,
          ].join("\n"),
        });
      } catch (error) {
        runtimeGlobals.console?.log(
          `⚠️ Email de boas-vindas não enviado para ${notificationEmail}:`,
          error instanceof Error ? error.message : error,
        );
      }

      runtimeGlobals.console?.log(`🎉 [CreateTenant] Tenant ${slug} pronto para utilização.`);

      return {
        id: tenant.id.toString(),
        tenantName: tenant.tenantName,
        tenantKey: tenant.tenantKey,
        status: tenantStatus,
        plan: { slug: plan.slug, name: plan.name },
        branch: {
          id: branch.id.toString(),
          code: branch.code,
          name: branch.name,
        },
      };
    } catch (error) {
      runtimeGlobals.console?.log(
        `❌ [CreateTenant] Falha ao provisionar BD; a reverter registos centrais.`,
        error instanceof Error ? error.message : error,
      );
      const now = new Date();
      await prisma.subscription.update({
        where: { id: subscription.id },
        data: { deletedAt: now, updatedBy: BigInt(data.userId) },
      }).catch(() => undefined);
      await prisma.branch.update({
        where: { id: branch.id },
        data: { deletedAt: now, active: false, updatedBy: BigInt(data.userId) },
      });
      await prisma.userTenant.updateMany({
        where: { tenantId: tenant.id, userId: BigInt(data.userId) },
        data: { active: false, deletedAt: now },
      });
      await prisma.tenant.update({
        where: { id: tenant.id },
        data: {
          deletedAt: now,
          updatedBy: BigInt(data.userId),
          name: `${slug}_deleted_${tenant.id}`,
        },
      });
      throw error instanceof Error
        ? error
        : new Error("Falha ao provisionar base de dados do tenant.");
    }
  }
}

/** @deprecated Use CreateTenantUseCase */
export const RegisterTenantUseCase = CreateTenantUseCase;

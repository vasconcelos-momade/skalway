import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { MySqlManagementService } from "../../../../../infrastructure/database/mysql-management.service";
import { syncTenantUsersFromCentral } from "../../../../../infrastructure/database/sync-tenant-users.service";
import { TenantPrismaFactory } from "../../../../../infrastructure/prisma/tenant-prisma.factory";
import { branchContext } from "../../../../../shared/context/branch-context";
import { encryptTenantDbPassword } from "../../../../../infrastructure/security/tenant-db-credentials";
import { EmailService } from "../../../../../infrastructure/notifications/email.service";
import { generateBranchCode } from "../../domain/generate-branch-code";
import {
  BRANCH_DB_NAME_PENDING,
  buildBranchDbName,
} from "../../domain/branch-db-name";
import { createTrialInvoice } from "../../../billing/application/services/create-trial-invoice.service";
import { SubscriptionBranchHistoryService } from "../../../billing/application/services/subscription-branch-history.service";
import { PrinterService } from "../../../printer/application/services/printer.service";
import { BranchSettingService } from "../../../branch-settings/application/services/branch-setting.service";
import { addDaysUTC, addMonthsUTC } from "@skalway/billing";

export interface CreateTenantBranchInput {
  name: string;
}

export interface CreateTenantDTO {
  /** Nome visível do tenant. */
  tenantName: string;
  /**
   * Identificador técnico. Se omitido, é gerado a partir de tenantName.
   * A UI não envia este campo — apenas o backend gera.
   */
  tenantKey?: string | null;
  /** Utilizador dono (central). */
  userId: string;
  email?: string | null;
  endereco?: string | null;
  nuit?: string | null;
  telefone?: string | null;
  planSlug?: string | null;
  status?: "trial" | "ativo" | null;
  /** @deprecated Preferir `branches`. */
  branchName?: string | null;
  /** Lista de branches a criar (a primeira é a principal). */
  branches?: CreateTenantBranchInput[] | null;
  /** Período de faturação em meses (1, 3, 6 ou 12). */
  billingPeriodMonths?: number | null;
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

function resolveBranchNames(data: CreateTenantDTO, tenantName: string): string[] {
  const fromList = (data.branches ?? [])
    .map((b) => b.name?.trim())
    .filter((name): name is string => Boolean(name));
  if (fromList.length > 0) return fromList;
  const single = data.branchName?.trim();
  return [single || tenantName];
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

    const branchNames = resolveBranchNames(data, tenantName);
    if (branchNames.length === 0) {
      throw new Error("É necessário informar pelo menos uma Branch.");
    }

    const dbPasswordPlain = runtimeGlobals.process?.env?.MYSQL_ROOT_PASSWORD;
    if (!dbPasswordPlain) {
      throw new Error("MYSQL_ROOT_PASSWORD não definido.");
    }
    const { cipherText, iv, tag } = encryptTenantDbPassword(dbPasswordPlain);
    const dbHost = runtimeGlobals.process?.env?.MYSQL_HOST || "phrx-db";
    const dbPort = Number(runtimeGlobals.process?.env?.MYSQL_PORT || 3306);

    const planSlug = (data.planSlug?.trim() || "starter").toLowerCase();
    const tenantStatus = data.status === "ativo" ? "ativo" : "trial";
    const branchesUsed = branchNames.length;
    const allowedPeriods = new Set([1, 3, 6, 12]);
    const billingPeriodMonths = allowedPeriods.has(
      Number(data.billingPeriodMonths),
    )
      ? Number(data.billingPeriodMonths)
      : 1;

    runtimeGlobals.console?.log(
      `🚀 [CreateTenant] Iniciando: ${slug} (${branchesUsed} branch(es))`,
    );

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
    const includedBranches = Number(plan.includedBranches ?? 1);
    const activePeriodEnd = addDaysUTC(
      addMonthsUTC(startDate, billingPeriodMonths),
      -1,
    );
    const activeNextBilling = addMonthsUTC(startDate, billingPeriodMonths);

    runtimeGlobals.console?.log(`📝 [CreateTenant] 1/6 Registo central (transação)...`);

    const { tenant, branches, subscription } = await prisma.$transaction(
      async (tx: any) => {
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
          settings.push({
            tenantId: tenant.id,
            key: "telefone",
            value: data.telefone.trim(),
          });
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
            branchesUsed,
            status: subscriptionStatus,
            startDate,
            trialEndsAt: subscriptionStatus === "trial" ? trialEndsAt : null,
            currentPeriodEnd:
              subscriptionStatus === "trial" ? trialEndsAt : activePeriodEnd,
            nextBillingAt:
              subscriptionStatus === "trial" ? trialEndsAt : activeNextBilling,
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
            branchesUsed,
            periodMonths: billingPeriodMonths,
          });
          if (invoice) {
            runtimeGlobals.console?.log(
              `🧾 [CreateTenant] Fatura trial ${invoice.invoiceNumber} (${invoice.amount} MZN) venc. ${invoice.dueDate.toISOString().slice(0, 10)}`,
            );
          }
        }

        const createdBranches: any[] = [];
        for (let i = 0; i < branchNames.length; i++) {
          const isHeadOffice = i === 0;
          const code = generateBranchCode();

          const branch = await tx.branch.create({
            data: {
              tenantId: tenant.id,
              code,
              name: branchNames[i],
              isHeadOffice,
              active: true,
              dbHost,
              dbPort,
              dbName: BRANCH_DB_NAME_PENDING,
              dbUsername: "root",
              dbPasswordCipherText: cipherText,
              dbPasswordIv: iv,
              dbPasswordTag: tag,
              createdBy: BigInt(data.userId),
              updatedBy: BigInt(data.userId),
            },
          });

          const dbName = buildBranchDbName(tenant.id, branch.id);
          const updatedBranch = await tx.branch.update({
            where: { id: branch.id },
            data: { dbName },
          });

          await new PrinterService().createDefaultPrinter({
            tx,
            tenantId: tenant.id,
            branchId: branch.id,
            userId: BigInt(data.userId),
          });

          await new BranchSettingService().seedDefaults({
            tx,
            tenantId: tenant.id,
            branchId: branch.id,
            defaults: {
              branchName: branch.name,
              branchCode: branch.code,
              // Nome legal = filial; NUIT/contacto só se enviados no formulário da unidade.
              nomeLegal: branch.name,
              nuit: data.nuit ?? null,
              email: null,
              endereco: data.endereco ?? null,
              telefone: data.telefone ?? null,
            },
          });

          await SubscriptionBranchHistoryService.recordBranchAdd({
            tx,
            tenantId: tenant.id,
            subscriptionId: subscription.id,
            branchId: branch.id,
            createdBy: BigInt(data.userId),
            includedBranches,
            branchCode: branch.code,
            branchName: branch.name,
            reason: isHeadOffice
              ? "Filial principal criada com o tenant"
              : "Filial adicional criada com o tenant",
          });

          createdBranches.push(updatedBranch);
        }

        return { tenant, branches: createdBranches, subscription };
      },
    );

    const hqBranch = branches[0];
    const hqDbName = hqBranch.dbName as string;

    try {
      runtimeGlobals.console?.log(`🛠  [CreateTenant] 3/6 Criar base de dados ${hqDbName}...`);
      await MySqlManagementService.createDatabase(hqDbName);

      runtimeGlobals.console?.log(`⚙️  [CreateTenant] 4/6 Migrations do tenant...`);
      MySqlManagementService.runMigrations(hqDbName);

      runtimeGlobals.console?.log(`🔐 [CreateTenant] 5/6 Seeders estruturais...`);
      MySqlManagementService.runStructuralSeed(hqDbName);

      runtimeGlobals.console?.log(`👤 [CreateTenant] 6/6 Sincronizar utilizadores...`);
      const ownerCentral = await prisma.user.findUnique({
        where: { id: BigInt(data.userId) },
        select: { id: true, name: true, email: true },
      });

      const tenantUserCount = await branchContext.run(
        {
          tenantId: tenant.id.toString(),
          branchId: hqBranch.id.toString(),
          dbName: hqDbName,
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
          });
        },
      );

      runtimeGlobals.console?.log(
        `👤 ${tenantUserCount} utilizador(es) tenant sincronizados em ${hqDbName}.`,
      );

      for (let i = 1; i < branches.length; i++) {
        const branch = branches[i];
        runtimeGlobals.console?.log(
          `🏢 [CreateTenant] Provisionar branch extra ${branch.name} (${branch.dbName})...`,
        );
        await MySqlManagementService.createDatabase(branch.dbName);
        MySqlManagementService.runMigrations(branch.dbName);
        MySqlManagementService.runStructuralSeed(branch.dbName);

        await branchContext.run(
          {
            tenantId: tenant.id.toString(),
            branchId: branch.id.toString(),
            dbName: branch.dbName,
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
            });
          },
        );
      }

      const notificationEmail = ownerCentral?.email ?? data.email?.trim() ?? null;
      const notificationName = ownerCentral?.name ?? tenantName;

      if (notificationEmail) {
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
              `Branches: ${branches.map((b: any) => `${b.name} (${b.code})`).join(", ")}.`,
              `Responsável registado: ${notificationName}.`,
            ].join("\n"),
          });
        } catch (error) {
          runtimeGlobals.console?.log(
            `⚠️ Email de boas-vindas não enviado para ${notificationEmail}:`,
            error instanceof Error ? error.message : error,
          );
        }
      }

      runtimeGlobals.console?.log(`🎉 [CreateTenant] Tenant ${slug} pronto para utilização.`);

      return {
        id: tenant.id.toString(),
        tenantName: tenant.tenantName,
        tenantKey: tenant.tenantKey,
        status: tenantStatus,
        plan: { slug: plan.slug, name: plan.name },
        branchesUsed,
        branch: {
          id: hqBranch.id.toString(),
          code: hqBranch.code,
          name: hqBranch.name,
        },
        branches: branches.map((b: any) => ({
          id: b.id.toString(),
          code: b.code,
          name: b.name,
          isHeadOffice: Boolean(b.isHeadOffice),
        })),
      };
    } catch (error) {
      runtimeGlobals.console?.log(
        `❌ [CreateTenant] Falha ao provisionar BD; a reverter registos centrais.`,
        error instanceof Error ? error.message : error,
      );
      const now = new Date();
      await prisma.subscription
        .update({
          where: { id: subscription.id },
          data: { deletedAt: now, updatedBy: BigInt(data.userId) },
        })
        .catch(() => undefined);
      await prisma.branch.updateMany({
        where: { tenantId: tenant.id },
        data: { deletedAt: now, active: false, updatedBy: BigInt(data.userId) },
      });
      await prisma.userTenant.updateMany({
        where: { tenantId: tenant.id },
        data: { active: false, deletedAt: now },
      });
      await prisma.tenant.update({
        where: { id: tenant.id },
        data: {
          deletedAt: now,
          updatedBy: BigInt(data.userId),
          tenantKey: `${slug}_deleted_${tenant.id}`,
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

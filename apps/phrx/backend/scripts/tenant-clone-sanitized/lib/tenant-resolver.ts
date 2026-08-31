import { prismaCentralUnscoped } from "../../../src/infrastructure/prisma/prisma-central.service";
import { buildBranchDbName } from "../../../src/modules/central/tenants/domain/branch-db-name";
import { assertSafeDbIdentifier } from "./protected-databases";

export type ResolvedBranch = {
  tenantId: string;
  tenantKey: string;
  tenantName: string;
  branchId: string;
  branchCode: string;
  branchName: string;
  dbName: string;
  isHeadOffice: boolean;
};

export type ResolveInput = {
  tenantKey?: string;
  dbName?: string;
  branchId?: string;
  branchCode?: string;
};

async function schemaExists(dbName: string): Promise<boolean> {
  const rows = await (prismaCentralUnscoped as any).$queryRawUnsafe<
    Array<{ c: bigint | number }>
  >(
    `SELECT COUNT(*) AS c
     FROM information_schema.SCHEMATA
     WHERE SCHEMA_NAME = ?`,
    dbName,
  );
  return Number(rows[0]?.c ?? 0) > 0;
}

/**
 * Resolve tenantKey + branch opcional para a base MySQL real.
 * Alternativamente aceita --source-db / --target-db directamente.
 */
export async function resolveBranchDatabase(
  input: ResolveInput,
  label: string,
): Promise<ResolvedBranch> {
  if (input.dbName) {
    const dbName = assertSafeDbIdentifier(input.dbName);
    const exists = await schemaExists(dbName);
    if (!exists) {
      throw new Error(`[${label}] Base "${dbName}" não existe no MySQL.`);
    }

    const branch = await prismaCentralUnscoped.branch.findFirst({
      where: { dbName, deletedAt: null },
      include: {
        tenant: {
          select: {
            id: true,
            tenantKey: true,
            tenantName: true,
            deletedAt: true,
          },
        },
      },
    });

    if (!branch || branch.tenant.deletedAt) {
      throw new Error(
        `[${label}] Base "${dbName}" existe mas não está registada numa Branch activa na Central.`,
      );
    }

    return {
      tenantId: branch.tenantId.toString(),
      tenantKey: branch.tenant.tenantKey,
      tenantName: branch.tenant.tenantName,
      branchId: branch.id.toString(),
      branchCode: branch.code,
      branchName: branch.name,
      dbName,
      isHeadOffice: branch.isHeadOffice,
    };
  }

  const tenantKey = String(input.tenantKey || "").trim();
  if (!tenantKey) {
    throw new Error(
      `[${label}] Especifique --${label}-db=<db_name> ou --${label}=<tenant_key>.`,
    );
  }

  const tenant = await prismaCentralUnscoped.tenant.findFirst({
    where: { tenantKey, deletedAt: null },
    select: {
      id: true,
      tenantKey: true,
      tenantName: true,
      branches: {
        where: { deletedAt: null, active: true },
        orderBy: [{ isHeadOffice: "desc" }, { id: "asc" }],
        select: {
          id: true,
          code: true,
          name: true,
          dbName: true,
          isHeadOffice: true,
        },
      },
    },
  });

  if (!tenant) {
    throw new Error(`[${label}] Tenant "${tenantKey}" não encontrado na Central.`);
  }

  if (tenant.branches.length === 0) {
    throw new Error(
      `[${label}] Tenant "${tenantKey}" não tem filiais activas.`,
    );
  }

  let branch = tenant.branches[0];

  if (input.branchId) {
    const found = tenant.branches.find((b) => b.id.toString() === input.branchId);
    if (!found) {
      throw new Error(
        `[${label}] Branch id=${input.branchId} não pertence ao tenant "${tenantKey}".`,
      );
    }
    branch = found;
  } else if (input.branchCode) {
    const code = input.branchCode.trim().toLowerCase();
    const found = tenant.branches.find(
      (b) => b.code.trim().toLowerCase() === code,
    );
    if (!found) {
      throw new Error(
        `[${label}] Branch código="${input.branchCode}" não encontrada no tenant "${tenantKey}".`,
      );
    }
    branch = found;
  } else if (tenant.branches.length > 1) {
    const list = tenant.branches
      .map(
        (b) =>
          `  - id=${b.id} code=${b.code} hq=${b.isHeadOffice} db=${b.dbName}`,
      )
      .join("\n");
    throw new Error(
      `[${label}] Tenant "${tenantKey}" tem ${tenant.branches.length} filiais. ` +
        `Especifique --${label}-branch-id ou --${label}-branch-code.\n${list}`,
    );
  }

  const expectedDbName = buildBranchDbName(tenant.id, branch.id);
  const dbName = assertSafeDbIdentifier(branch.dbName || expectedDbName);

  if (branch.dbName !== expectedDbName) {
    console.warn(
      `⚠️  [${label}] Branch.dbName="${branch.dbName}" difere do canónico "${expectedDbName}". Usando registo Central.`,
    );
  }

  const exists = await schemaExists(dbName);
  if (!exists) {
    throw new Error(`[${label}] Base "${dbName}" não existe no MySQL.`);
  }

  return {
    tenantId: tenant.id.toString(),
    tenantKey: tenant.tenantKey,
    tenantName: tenant.tenantName,
    branchId: branch.id.toString(),
    branchCode: branch.code,
    branchName: branch.name,
    dbName,
    isHeadOffice: branch.isHeadOffice,
  };
}

export async function disconnectCentral(): Promise<void> {
  await prismaCentralUnscoped.$disconnect().catch(() => undefined);
}

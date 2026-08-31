/**
 * Sincroniza categorias FNM em todos os tenants activos (ou um tenant específico).
 * Uso:
 *   bun scripts/seed-fnm-categorias-all-tenants.ts
 *   bun scripts/seed-fnm-categorias-all-tenants.ts phrx_tenant_1_branch_1
 */
import { PrismaClient as PrismaCentralClient } from "../src/infrastructure/prisma/central/generated/central";
import { PrismaClient as PrismaTenantClient } from "../src/infrastructure/prisma/tenant/generated/tenant";
import { syncFnmCategorias } from "../src/modules/tenant/products/domain/sync-fnm-categorias";

const TENANT_DB_HOST = process.env.TENANT_DB_HOST || "phrx-db";
const TENANT_DB_PORT = process.env.TENANT_DB_PORT || "3306";
const TENANT_DB_USERNAME = process.env.TENANT_DB_USERNAME || "root";
const TENANT_DB_PASSWORD = process.env.TENANT_DB_PASSWORD || "root_password";

function buildTenantDbUrl(dbName: string): string {
  return `mysql://${TENANT_DB_USERNAME}:${TENANT_DB_PASSWORD}@${TENANT_DB_HOST}:${TENANT_DB_PORT}/${dbName}`;
}

async function listTenantDbNames(explicitDbName?: string): Promise<string[]> {
  if (explicitDbName) {
    return [explicitDbName];
  }

  const central = new PrismaCentralClient();
  try {
    const branches = await central.branch.findMany({
      where: { deletedAt: null, active: true },
      select: { dbName: true },
      distinct: ["dbName"],
    });
    return branches.map((branch) => branch.dbName);
  } finally {
    await central.$disconnect();
  }
}

async function syncTenant(dbName: string): Promise<number> {
  const prisma = new PrismaTenantClient({
    datasources: { db: { url: buildTenantDbUrl(dbName) } },
  });

  try {
    await syncFnmCategorias(prisma);
    return prisma.categoria.count({
      where: { codigoFNM: { not: null }, deletedAt: null, ativo: true },
    });
  } finally {
    await prisma.$disconnect();
  }
}

async function main() {
  const explicitDbName = process.argv[2];
  const dbNames = await listTenantDbNames(explicitDbName);

  if (dbNames.length === 0) {
    console.error("Nenhum tenant activo encontrado.");
    process.exit(1);
  }

  console.log(`🌱 Sincronizando categorias FNM em ${dbNames.length} tenant(s)...`);

  for (const dbName of dbNames) {
    try {
      const total = await syncTenant(dbName);
      console.log(`✅ ${dbName}: ${total} categorias FNM activas`);
    } catch (error) {
      console.error(`❌ ${dbName}:`, error);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

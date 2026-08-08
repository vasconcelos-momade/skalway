/**
 * Renomeia bases MySQL de Branches para o padrão canónico
 * `phrx_tenant_{tenantId}_branch_{branchId}` e actualiza `Branch.dbName`.
 *
 * Não altera dados das tabelas — só naming e referências.
 *
 * Uso:
 *   bun scripts/rename-branch-databases.ts           # dry-run
 *   bun scripts/rename-branch-databases.ts --apply  # aplica
 */
import { prismaCentralUnscoped } from "../src/infrastructure/prisma/prisma-central.service";
import { MySqlManagementService } from "../src/infrastructure/database/mysql-management.service";
import {
  buildBranchDbName,
  isCanonicalBranchDbName,
} from "../src/modules/central/tenants/domain/branch-db-name";

const APPLY = process.argv.includes("--apply");

async function schemaExists(dbName: string): Promise<boolean> {
  const rows = await (prismaCentralUnscoped as any).$queryRawUnsafe(
    `SELECT COUNT(*) AS c
     FROM information_schema.SCHEMATA
     WHERE SCHEMA_NAME = ?`,
    dbName,
  );
  return Number(rows[0]?.c ?? 0) > 0;
}

async function countTables(dbName: string): Promise<number> {
  const rows = await (prismaCentralUnscoped as any).$queryRawUnsafe(
    `SELECT COUNT(*) AS c
     FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = ?`,
    dbName,
  );
  return Number(rows[0]?.c ?? 0);
}

async function main() {
  const prisma = prismaCentralUnscoped as any;
  const branches = await prisma.branch.findMany({
    where: { deletedAt: null },
    orderBy: [{ tenantId: "asc" }, { id: "asc" }],
    select: {
      id: true,
      tenantId: true,
      code: true,
      name: true,
      dbName: true,
      isHeadOffice: true,
    },
  });

  console.log(
    `==> ${branches.length} branch(es) activas. Modo: ${APPLY ? "APPLY" : "DRY-RUN"}`,
  );

  const plan: Array<{
    branchId: string;
    tenantId: string;
    name: string;
    from: string;
    to: string;
    action: "skip" | "rename" | "update-ref-only" | "missing-source";
  }> = [];

  for (const branch of branches) {
    const tenantId = branch.tenantId.toString();
    const branchId = branch.id.toString();
    const from = String(branch.dbName);
    const to = buildBranchDbName(tenantId, branchId);

    if (from === to && isCanonicalBranchDbName(from)) {
      plan.push({
        branchId,
        tenantId,
        name: branch.name,
        from,
        to,
        action: "skip",
      });
      continue;
    }

    const sourceExists = await schemaExists(from);
    const targetExists = await schemaExists(to);

    if (!sourceExists && targetExists && from !== to) {
      // DB já renomeada; só falta actualizar Branch.dbName
      plan.push({
        branchId,
        tenantId,
        name: branch.name,
        from,
        to,
        action: "update-ref-only",
      });
      continue;
    }

    if (!sourceExists) {
      plan.push({
        branchId,
        tenantId,
        name: branch.name,
        from,
        to,
        action: "missing-source",
      });
      continue;
    }

    plan.push({
      branchId,
      tenantId,
      name: branch.name,
      from,
      to,
      action: "rename",
    });
  }

  for (const item of plan) {
    console.log(
      `  [${item.action}] branch=${item.branchId} tenant=${item.tenantId} «${item.name}»`,
    );
    console.log(`           ${item.from} → ${item.to}`);
  }

  const toProcess = plan.filter((p) => p.action !== "skip");
  if (toProcess.length === 0) {
    console.log("✅ Todas as branches já usam o naming canónico.");
    return;
  }

  if (!APPLY) {
    console.log("");
    console.log("Dry-run concluído. Para aplicar:");
    console.log("  bun scripts/rename-branch-databases.ts --apply");
    return;
  }

  const missing = plan.filter((p) => p.action === "missing-source");
  if (missing.length > 0) {
    throw new Error(
      `${missing.length} branch(es) apontam para bases inexistentes. Abortado.`,
    );
  }

  for (const item of plan) {
    if (item.action === "skip") continue;

    if (item.action === "rename") {
      const before = await countTables(item.from);
      console.log(`\n🔁 Renomear ${item.from} → ${item.to} (${before} tabelas)...`);
      await MySqlManagementService.renameDatabase(item.from, item.to);
      const after = await countTables(item.to);
      if (after !== before) {
        throw new Error(
          `Contagem de tabelas divergiu após rename (${before} → ${after}).`,
        );
      }
    }

    await prisma.branch.update({
      where: { id: BigInt(item.branchId) },
      data: { dbName: item.to },
    });
    console.log(`✅ Branch ${item.branchId}: dbName actualizado para ${item.to}`);
  }

  console.log("\n✅ Migração de naming concluída.");
}

main()
  .catch((error) => {
    console.error("❌ Falha:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await (prismaCentralUnscoped as any).$disconnect?.().catch(() => undefined);
  });

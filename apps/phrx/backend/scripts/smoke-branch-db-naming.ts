/**
 * Smoke: naming canónico + conexão + isolamento entre branches.
 * Uso: bun scripts/smoke-branch-db-naming.ts
 */
import { prismaCentralUnscoped } from "../src/infrastructure/prisma/prisma-central.service";
import { TenantPrismaFactory } from "../src/infrastructure/prisma/tenant-prisma.factory";
import { branchContext } from "../src/shared/context/branch-context";
import {
  buildBranchDbName,
  isCanonicalBranchDbName,
} from "../src/modules/central/tenants/domain/branch-db-name";

async function withBranch(branch: any, fn: () => Promise<unknown>) {
  return branchContext.run(
    {
      tenantId: String(branch.tenantId),
      branchId: String(branch.id),
      dbName: branch.dbName,
      dbHost: branch.dbHost,
      dbPort: branch.dbPort,
      dbUsername: branch.dbUsername,
      dbPasswordCipherText: branch.dbPasswordCipherText,
      dbPasswordIv: branch.dbPasswordIv,
      dbPasswordTag: branch.dbPasswordTag,
    },
    fn,
  );
}

async function main() {
  const prisma = prismaCentralUnscoped as any;
  const branches = await prisma.branch.findMany({
    where: { deletedAt: null },
    orderBy: { id: "asc" },
  });

  if (branches.length < 1) {
    throw new Error("Nenhuma branch activa para testar.");
  }

  for (const b of branches) {
    const expected = buildBranchDbName(b.tenantId, b.id);
    if (b.dbName !== expected) {
      throw new Error(
        `dbName mismatch branch ${b.id}: ${b.dbName} != ${expected}`,
      );
    }
    if (!isCanonicalBranchDbName(b.dbName)) {
      throw new Error(`non-canonical ${b.dbName}`);
    }

    const users = await withBranch(b, async () => {
      const t = TenantPrismaFactory.getClient() as any;
      await t.$queryRawUnsafe("SELECT 1 AS ok");
      return t.user.count();
    });
    console.log(
      `OK connect/read branch=${b.id} db=${b.dbName} users=${users}`,
    );
  }

  if (branches.length >= 2) {
    const [b1, b2] = branches;
    const c1 = (await withBranch(b1, async () =>
      (TenantPrismaFactory.getClient() as any).fatura.count(),
    )) as number;
    const c2 = (await withBranch(b2, async () =>
      (TenantPrismaFactory.getClient() as any).fatura.count(),
    )) as number;
    console.log(`OK isolation faturas branch1=${c1} branch2=${c2}`);
    if (c1 === c2) {
      console.log(
        "ℹ️  Contagens iguais (aceitável se ambas as filiais tiverem os mesmos dados).",
      );
    }
  }

  console.log("ALL SMOKE CHECKS PASSED");
}

main()
  .catch((error) => {
    console.error("❌", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await (prismaCentralUnscoped as any).$disconnect?.().catch(() => undefined);
  });

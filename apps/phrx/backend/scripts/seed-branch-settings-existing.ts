import { prismaCentralUnscoped } from "../src/infrastructure/prisma/prisma-central.service";
import { BranchSettingService } from "../src/modules/central/branch-settings/application/services/branch-setting.service";

const prisma = prismaCentralUnscoped as any;
const branches = await prisma.branch.findMany({
  where: { deletedAt: null },
  include: {
    tenant: {
      select: { tenantName: true, nuit: true, email: true, endereco: true },
    },
  },
});

const svc = new BranchSettingService();
for (const b of branches) {
  const result = await prisma.$transaction(async (tx: any) =>
    svc.seedDefaults({
      tx,
      tenantId: b.tenantId,
      branchId: b.id,
      defaults: {
        branchName: b.name,
        nomeLegal: b.tenant?.tenantName ?? b.name,
        nuit: b.tenant?.nuit ?? null,
        email: b.tenant?.email ?? null,
        endereco: b.tenant?.endereco ?? null,
      },
    }),
  );
  console.log(`branch ${b.id} ${b.name}:`, result);
}

console.log(`Seeded ${branches.length} branch(es).`);

/**
 * Corrige seeds antigos: fiscal.nomeLegal / branch.email não devem
 * herdar o nome/e-mail do dono do tenant — usam o nome da filial.
 */
import { prismaCentralUnscoped } from "../src/infrastructure/prisma/prisma-central.service";

const prisma = prismaCentralUnscoped as any;

const branches = await prisma.branch.findMany({
  where: { deletedAt: null },
  select: { id: true, tenantId: true, name: true },
});

for (const b of branches) {
  await prisma.$transaction(async (tx: any) => {
    const nomeLegal = await tx.branchSetting.findFirst({
      where: {
        tenantId: b.tenantId,
        branchId: b.id,
        key: "fiscal.nomeLegal",
        deletedAt: null,
      },
    });
    if (nomeLegal) {
      await tx.branchSetting.update({
        where: { id: nomeLegal.id },
        data: { value: b.name, version: { increment: 1 } },
      });
    }

    const email = await tx.branchSetting.findFirst({
      where: {
        tenantId: b.tenantId,
        branchId: b.id,
        key: "branch.email",
        deletedAt: null,
      },
    });
    if (email) {
      await tx.branchSetting.update({
        where: { id: email.id },
        data: { value: null, version: { increment: 1 } },
      });
    }

    const nameRow = await tx.branchSetting.findFirst({
      where: {
        tenantId: b.tenantId,
        branchId: b.id,
        key: "branch.name",
        deletedAt: null,
      },
    });
    if (nameRow && String(nameRow.value).replaceAll('"', "") !== b.name) {
      await tx.branchSetting.update({
        where: { id: nameRow.id },
        data: { value: b.name, version: { increment: 1 } },
      });
    }
  });
  console.log(`fixed branch ${b.id}: ${b.name}`);
}

console.log("done");

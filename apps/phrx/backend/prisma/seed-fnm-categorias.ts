import { PrismaClient } from "../src/infrastructure/prisma/tenant/generated/tenant";
import { syncFnmCategorias } from "../src/modules/tenant/products/domain/sync-fnm-categorias";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Seed categorias FNM...");

  await syncFnmCategorias(prisma);

  const total = await prisma.categoria.count({
    where: { codigoFNM: { not: null }, deletedAt: null, ativo: true },
  });

  console.log(`✅ Categorias FNM activas: ${total}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

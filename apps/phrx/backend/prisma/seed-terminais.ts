import { PrismaClient } from "../src/infrastructure/prisma/tenant/generated/tenant";

/**
 * Seed estrutural: terminais POS e caixas associados.
 * Sem produtos, lotes ou movimentos de estoque.
 */
const prisma = new PrismaClient();

async function main() {
  console.log("🚀 [seed-terminais] Terminais e caixas...");

  const terminal1 = await prisma.terminal.upsert({
    where: { id: BigInt(1) },
    update: { nome: "Terminal 01 - Balcão Principal", codigo: "T01", ativo: true },
    create: {
      id: BigInt(1),
      nome: "Terminal 01 - Balcão Principal",
      codigo: "T01",
      ativo: true,
    },
  });

  const terminal2 = await prisma.terminal.upsert({
    where: { id: BigInt(2) },
    update: { nome: "Terminal 02 - Balcão Secundário", codigo: "T02", ativo: true },
    create: {
      id: BigInt(2),
      nome: "Terminal 02 - Balcão Secundário",
      codigo: "T02",
      ativo: true,
    },
  });

  await (prisma as any).caixa.upsert({
    where: { terminalId: terminal1.id },
    update: {},
    create: {
      terminalId: terminal1.id,
      saldoAtual: 0,
    },
  });

  await (prisma as any).caixa.upsert({
    where: { terminalId: terminal2.id },
    update: {},
    create: {
      terminalId: terminal2.id,
      saldoAtual: 0,
    },
  });

  console.log("✅ [seed-terminais] Terminais T01/T02 e caixas prontos.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

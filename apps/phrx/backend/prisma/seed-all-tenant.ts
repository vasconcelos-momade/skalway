/**
 * Orquestrador completo: seeders estruturais + dados de demonstração.
 * Preferir seed-tenant.ts (criação) e seed-demo.ts (manual) em separado.
 *
 * Uso: bun prisma/seed-all-tenant.ts <nome-do-banco>
 */
import { spawn } from "child_process";
import path from "path";

async function runScript(scriptPath: string, dbName: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn("bun", [scriptPath, dbName], {
      env: { ...process.env },
      cwd: path.resolve(__dirname, ".."),
      stdio: "inherit",
    });

    child.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Script ${scriptPath} exited with code ${code}`));
      }
    });

    child.on("error", reject);
  });
}

async function main() {
  const dbName = process.argv[2];

  if (!dbName) {
    console.error("❌ Por favor, forneça o nome do banco de dados do tenant.");
    console.error("Uso: bun prisma/seed-all-tenant.ts <nome-do-banco>");
    console.error("Exemplo: bun prisma/seed-all-tenant.ts phrx_tenant_1_branch_1");
    process.exit(1);
  }

  console.log(`🚀 [seed-all] Seed completo (estrutural + demo) para: ${dbName}\n`);

  console.log("── Parte 1: seeders estruturais ──");
  await runScript("prisma/seed-tenant.ts", dbName);

  console.log("\n── Parte 2: dados de demonstração ──");
  await runScript("prisma/seed-demo.ts", dbName);

  console.log(`\n🎉 [seed-all] Seed completo para ${dbName} concluído.`);
}

main().catch((error) => {
  console.error("\n❌ [seed-all] Erro:", error);
  process.exit(1);
});

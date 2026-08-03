/**
 * Seed de demonstração do tenant — dados fictícios (NÃO corre na criação do tenant).
 * Inclui: medicamentos ANARME, serviços, lotes e movimentações.
 * Terminais/caixas ficam em seed-tenant.ts (estrutural).
 *
 * Pré-requisito: seed-tenant.ts (estrutural) já executado.
 *
 * Uso:
 *   bun prisma/seed-demo.ts <nome-do-banco>
 *   DATABASE_URL_TENANT=... bun prisma/seed-demo.ts
 */
import { spawn } from "child_process";
import path from "path";

const TENANT_DB_HOST = process.env.TENANT_DB_HOST || "phrx-db";
const TENANT_DB_PORT = process.env.TENANT_DB_PORT || "3306";
const TENANT_DB_USERNAME = process.env.TENANT_DB_USERNAME || "root";
const TENANT_DB_PASSWORD = process.env.TENANT_DB_PASSWORD || "root_password";

function buildTenantDbUrl(dbName: string): string {
  return `mysql://${TENANT_DB_USERNAME}:${TENANT_DB_PASSWORD}@${TENANT_DB_HOST}:${TENANT_DB_PORT}/${dbName}`;
}

function resolveDbUrl(): string {
  const dbName = process.argv[2];
  if (dbName) {
    return buildTenantDbUrl(dbName);
  }
  const fromEnv = process.env.DATABASE_URL_TENANT?.trim();
  if (fromEnv) {
    return fromEnv;
  }
  throw new Error(
    "Indique o nome da BD (bun prisma/seed-demo.ts <db>) ou DATABASE_URL_TENANT.",
  );
}

async function runScript(scriptPath: string, dbUrl: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn("bun", [scriptPath], {
      env: {
        ...process.env,
        DATABASE_URL_TENANT: dbUrl,
      },
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
  const dbUrl = resolveDbUrl();
  const dbLabel = dbUrl.split("/").pop() ?? "tenant";

  console.log(`🚀 [seed-demo] Dados de demonstração para: ${dbLabel}`);
  console.log(`📊 URL: ${dbUrl.replace(/:[^:]*@/, ":***@")}`);
  console.log("⚠️  Pode demorar 20–30 min (medicamentos ANARME).\n");

  console.log("1️⃣  Medicamentos ANARME...");
  await runScript("prisma/seed-medicamentos.ts", dbUrl);
  console.log("✅ Medicamentos concluído.\n");

  console.log("2️⃣  Serviços clínicos...");
  await runScript("prisma/seed-servicos.ts", dbUrl);
  console.log("✅ Serviços concluído.\n");

  console.log("3️⃣  Estoque (lotes + movimentações)...");
  await runScript("prisma/seed-estoque.ts", dbUrl);
  console.log("✅ Estoque concluído.\n");

  console.log(`🎉 [seed-demo] Dados de demonstração concluídos para ${dbLabel}.`);
}

main().catch((error) => {
  console.error("\n❌ [seed-demo] Erro:", error);
  process.exit(1);
});

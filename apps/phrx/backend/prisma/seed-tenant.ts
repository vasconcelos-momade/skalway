/**
 * Seed estrutural do tenant — dados obrigatórios para o tenant ficar operacional.
 * Inclui: roles, permissões, Consumidor Final, FNM, impostos, terminais/caixas.
 * NÃO inclui produtos, lotes, movimentações nem dados de demonstração.
 *
 * Uso:
 *   bun prisma/seed-tenant.ts <nome-do-banco>
 *   DATABASE_URL_TENANT=... bun prisma/seed-tenant.ts
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
    "Indique o nome da BD (bun prisma/seed-tenant.ts <db>) ou DATABASE_URL_TENANT.",
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

  console.log(`🚀 [seed-tenant] Seeders estruturais para: ${dbLabel}`);
  console.log(`📊 URL: ${dbUrl.replace(/:[^:]*@/, ":***@")}\n`);

  console.log("1️⃣  Roles e permissões...");
  await runScript("prisma/seed-role-permissions.ts", dbUrl);
  console.log("✅ Roles e permissões concluído.\n");

  console.log("2️⃣  Cliente padrão Consumidor Final...");
  await runScript("prisma/seed-consumidor-final.ts", dbUrl);
  console.log("✅ Consumidor Final concluído.\n");

  console.log("3️⃣  Categorias FNM...");
  await runScript("prisma/seed-fnm-categorias.ts", dbUrl);
  console.log("✅ Categorias FNM concluído.\n");

  console.log("4️⃣  Regras fiscais (impostos)...");
  await runScript("src/infrastructure/prisma/tenant/seed-tax-rules.ts", dbUrl);
  console.log("✅ Regras fiscais concluído.\n");

  console.log("5️⃣  Terminais e caixas...");
  await runScript("prisma/seed-terminais.ts", dbUrl);
  console.log("✅ Terminais e caixas concluído.\n");

  console.log("6️⃣  Serviços clínicos (POS / Proforma)...");
  await runScript("prisma/seed-servicos.ts", dbUrl);
  console.log("✅ Serviços clínicos concluído.\n");

  console.log(`🎉 [seed-tenant] Seeders estruturais concluídos para ${dbLabel}.`);
}

main().catch((error) => {
  console.error("\n❌ [seed-tenant] Erro:", error);
  process.exit(1);
});

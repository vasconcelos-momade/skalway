#!/usr/bin/env bun
/**
 * Cópia sanitizada de tenant de produção → tenant de teste.
 *
 * Fluxo obrigatório:
 *   PRODUÇÃO (read-only) → dump → base temporária → sanitização → dump → TESTE
 *
 * Uso:
 *   bun run tenant:clone-sanitized -- --source=tenant_producao --target=tenant_teste --dry-run
 *   bun run tenant:clone-sanitized -- --source-db=phrx_tenant_1_branch_1 --target-db=phrx_tenant_2_branch_1
 *   bun run tenant:clone-sanitized -- --source=farmacia_prod --target=farmacia_test --source-branch-id=1 --yes
 *
 * Variáveis de ambiente:
 *   PROTECTED_DATABASES  Lista extra de bases protegidas (vírgula)
 *   MYSQL_ROOT_PASSWORD    Password root MySQL
 *   MYSQL_CONTAINER        Container Docker (default: phrx_mysql)
 */
import { createInterface } from "readline";
import { existsSync, mkdirSync, rmSync } from "fs";
import { join } from "path";
import {
  assertNotProductionTarget,
  assertSourceIsReadOnly,
  getProtectedDatabases,
} from "./lib/protected-databases";
import {
  buildTempSanitizeDbName,
  countTablesAndRows,
  createDatabase,
  databaseExists,
  describeMysqlMode,
  dropDatabase,
  dumpDatabase,
  loadMysqlCliConfig,
  recreateDatabase,
  restoreDatabase,
} from "./lib/mysql-cli";
import {
  formatSanitizeSummary,
  sanitizeTenantDatabase,
} from "./lib/sanitize-tenant-db";
import {
  disconnectCentral,
  resolveBranchDatabase,
  type ResolvedBranch,
} from "./lib/tenant-resolver";

type CliOptions = {
  sourceKey?: string;
  targetKey?: string;
  sourceDb?: string;
  targetDb?: string;
  sourceBranchId?: string;
  targetBranchId?: string;
  sourceBranchCode?: string;
  targetBranchCode?: string;
  dryRun: boolean;
  yes: boolean;
  keepTemp: boolean;
  backupDir?: string;
};

function parseArgs(argv: string[]): CliOptions {
  const opts: CliOptions = {
    dryRun: false,
    yes: false,
    keepTemp: false,
  };

  for (const arg of argv) {
    if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--yes" || arg === "-y") opts.yes = true;
    else if (arg === "--keep-temp") opts.keepTemp = true;
    else if (arg.startsWith("--source=")) opts.sourceKey = arg.slice("--source=".length);
    else if (arg.startsWith("--target=")) opts.targetKey = arg.slice("--target=".length);
    else if (arg.startsWith("--source-db=")) opts.sourceDb = arg.slice("--source-db=".length);
    else if (arg.startsWith("--target-db=")) opts.targetDb = arg.slice("--target-db=".length);
    else if (arg.startsWith("--source-branch-id=")) opts.sourceBranchId = arg.slice("--source-branch-id=".length);
    else if (arg.startsWith("--target-branch-id=")) opts.targetBranchId = arg.slice("--target-branch-id=".length);
    else if (arg.startsWith("--source-branch-code=")) opts.sourceBranchCode = arg.slice("--source-branch-code=".length);
    else if (arg.startsWith("--target-branch-code=")) opts.targetBranchCode = arg.slice("--target-branch-code=".length);
    else if (arg.startsWith("--backup-dir=")) opts.backupDir = arg.slice("--backup-dir=".length);
    else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      console.error(`Argumento desconhecido: ${arg}`);
      printHelp();
      process.exit(1);
    }
  }

  return opts;
}

function printHelp(): void {
  console.log(`
Cópia sanitizada de tenant (produção → teste)

Uso:
  bun run tenant:clone-sanitized -- --source=<tenant_key> --target=<tenant_key> [opções]

Opções:
  --source=<tenant_key>         Tenant de origem (slug)
  --target=<tenant_key>         Tenant de destino (teste)
  --source-db=<db_name>         Base MySQL de origem (alternativa ao slug)
  --target-db=<db_name>         Base MySQL de destino
  --source-branch-id=<id>       Filial de origem (se multi-filial)
  --target-branch-id=<id>       Filial de destino
  --source-branch-code=<code>   Código da filial de origem
  --target-branch-code=<code>   Código da filial de destino
  --backup-dir=<path>           Diretório para backups (default: ./backups/tenant-clone)
  --dry-run                     Simular sem alterar bases
  --yes, -y                     Confirmar sobrescrita do destino sem prompt
  --keep-temp                   Não apagar base temporária após sucesso
  --help, -h                    Mostrar ajuda

Exemplo dry-run:
  bun run tenant:clone-sanitized -- --source=farmacia_prod --target=farmacia_test --dry-run
`);
}

function logStep(step: number, message: string): void {
  console.log(`\n[${step}/10] ${message}`);
}

function describeBranch(branch: ResolvedBranch): string {
  return `${branch.tenantKey} / ${branch.branchName} (db=${branch.dbName})`;
}

async function confirmOverwrite(target: ResolvedBranch): Promise<boolean> {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const answer = await new Promise<string>((resolve) => {
    rl.question(
      `\n⚠️  Isto vai SOBRESCREVER completamente o tenant de teste:\n` +
        `   ${describeBranch(target)}\n` +
        `   Um backup será criado antes. Continuar? [y/N] `,
      resolve,
    );
  });
  rl.close();
  return answer.trim().toLowerCase() === "y" || answer.trim().toLowerCase() === "yes";
}

async function main(): Promise<void> {
  const opts = parseArgs(process.argv.slice(2));
  const mysqlConfig = loadMysqlCliConfig();
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const workDir =
    opts.backupDir ??
    process.env.BACKUP_DIR ??
    join(process.cwd(), "backups", "tenant-clone", timestamp);

  console.log("═══════════════════════════════════════════════════════════");
  console.log("  PhRx — Cópia Sanitizada de Tenant");
  console.log("═══════════════════════════════════════════════════════════");
  console.log(`Modo MySQL: ${describeMysqlMode(mysqlConfig)}`);
  console.log(`Modo execução: ${opts.dryRun ? "DRY-RUN (sem alterações)" : "REAL"}`);
  console.log(`Bases protegidas: ${[...getProtectedDatabases()].join(", ")}`);
  if (process.env.PROTECTED_DATABASES) {
    console.log(`PROTECTED_DATABASES: ${process.env.PROTECTED_DATABASES}`);
  }

  // ── 1. Resolver origem e destino ──
  logStep(1, "A resolver origem e destino...");
  const source = await resolveBranchDatabase(
    {
      tenantKey: opts.sourceKey,
      dbName: opts.sourceDb,
      branchId: opts.sourceBranchId,
      branchCode: opts.sourceBranchCode,
    },
    "source",
  );
  const target = await resolveBranchDatabase(
    {
      tenantKey: opts.targetKey,
      dbName: opts.targetDb,
      branchId: opts.targetBranchId,
      branchCode: opts.targetBranchCode,
    },
    "target",
  );

  const tempDb = buildTempSanitizeDbName();

  console.log(`  Origem:  ${describeBranch(source)}`);
  console.log(`  Destino: ${describeBranch(target)}`);
  console.log(`  Temp:    ${tempDb}`);
  console.log(`  WorkDir: ${workDir}`);

  // ── 2. Validações de segurança ──
  logStep(2, "A validar regras de segurança...");
  assertSourceIsReadOnly(source.dbName, target.dbName, tempDb);

  // Origem nunca pode ser alvo destrutivo
  try {
    assertNotProductionTarget(source.dbName, "validação origem");
    // Se origem está na lista protegida, é OK para LEITURA — apenas bloqueamos escrita nela
  } catch {
    console.log(
      `  ℹ️  Origem "${source.dbName}" está na lista de bases protegidas — apenas leitura (mysqldump).`,
    );
  }

  // Destino não pode ser base protegida de produção
  assertNotProductionTarget(target.dbName, "validação destino");

  if (opts.dryRun) {
    console.log("  ✅ Validações OK (dry-run).");
  }

  const sourceDumpPath = join(workDir, `source-${source.dbName}.sql`);
  const targetBackupPath = join(workDir, `target-backup-${target.dbName}.sql`);
  const sanitizedDumpPath = join(workDir, `sanitized-${source.dbName}.sql`);

  if (opts.dryRun) {
    logStep(3, "Plano de execução (dry-run):");
    console.log(`
  1. mysqldump --single-transaction ${source.dbName} → ${sourceDumpPath}
     (READ-ONLY na origem — sem DELETE/UPDATE/DROP)
  2. Backup destino: mysqldump ${target.dbName} → ${targetBackupPath}
  3. CREATE DATABASE ${tempDb}
  4. mysql ${tempDb} < ${sourceDumpPath}
  5. Sanitização em ${tempDb} (users, clientes, logs, tokens...)
  6. mysqldump ${tempDb} → ${sanitizedDumpPath}
  7. DROP + CREATE ${target.dbName}; mysql ${target.dbName} < ${sanitizedDumpPath}
  8. Validações finais + resumo
  9. DROP DATABASE ${tempDb}; limpar ficheiros temporários

  Comando real:
    bun run tenant:clone-sanitized -- --source=${source.tenantKey} --target=${target.tenantKey} --yes
`);
    await disconnectCentral();
    return;
  }

  // ── 3. Confirmação ──
  if (!opts.yes) {
    const confirmed = await confirmOverwrite(target);
    if (!confirmed) {
      console.log("\n❌ Operação cancelada pelo utilizador.");
      await disconnectCentral();
      process.exit(1);
    }
  }

  mkdirSync(workDir, { recursive: true });
  let success = false;

  try {
    // ── 4. Backup do tenant de teste ──
    logStep(3, `A criar backup de segurança do destino (${target.dbName})...`);
    assertNotProductionTarget(target.dbName, "backup destino");
    dumpDatabase(mysqlConfig, target.dbName, targetBackupPath);
    console.log(`  ✅ Backup destino: ${targetBackupPath}`);

    // ── 5. Dump da origem (READ-ONLY) ──
    logStep(4, `A exportar origem (${source.dbName}) — SOMENTE LEITURA...`);
    dumpDatabase(mysqlConfig, source.dbName, sourceDumpPath);
    console.log(`  ✅ Dump origem: ${sourceDumpPath}`);

    const sourceStats = await countTablesAndRows(source.dbName);
    console.log(
      `  📊 Origem: ${sourceStats.tables} tabelas, ~${sourceStats.rows} registos`,
    );

    // ── 6. Base temporária de sanitização ──
    logStep(5, `A criar base temporária (${tempDb})...`);
    createDatabase(mysqlConfig, tempDb, "criar base temporária");

    logStep(6, `A restaurar dump na base temporária...`);
    restoreDatabase(mysqlConfig, tempDb, sourceDumpPath, "restaurar base temporária");

    // ── 7. Sanitização ──
    logStep(7, `A sanitizar dados em ${tempDb}...`);
    const sanitizeSummary = await sanitizeTenantDatabase(tempDb);
    console.log("  Resumo sanitização:");
    console.log(formatSanitizeSummary(sanitizeSummary));

    // ── 8. Dump sanitizado ──
    logStep(8, `A gerar dump sanitizado...`);
    dumpDatabase(mysqlConfig, tempDb, sanitizedDumpPath);
    console.log(`  ✅ Dump sanitizado: ${sanitizedDumpPath}`);

    // ── 9. Restaurar no tenant de teste ──
    logStep(9, `A restaurar no destino (${target.dbName})...`);
    assertNotProductionTarget(target.dbName, "recriar destino");
    recreateDatabase(mysqlConfig, target.dbName, "recriar destino");
    restoreDatabase(mysqlConfig, target.dbName, sanitizedDumpPath, "restaurar destino");

    // ── 10. Validações finais ──
    logStep(10, "Validações finais...");
    const targetStats = await countTablesAndRows(target.dbName);
    console.log(
      `  📊 Destino: ${targetStats.tables} tabelas, ~${targetStats.rows} registos`,
    );

    if (targetStats.tables < sourceStats.tables) {
      console.warn(
        `  ⚠️  Destino tem menos tabelas que origem (${targetStats.tables} vs ${sourceStats.tables}).`,
      );
    }

    console.log("\n═══════════════════════════════════════════════════════════");
    console.log("  ✅ Cópia sanitizada concluída com sucesso!");
    console.log("═══════════════════════════════════════════════════════════");
    console.log(`  Origem (inalterada): ${source.dbName}`);
    console.log(`  Destino (atualizado): ${target.dbName}`);
    console.log(`  Backup destino: ${targetBackupPath}`);
    console.log(`  Dump sanitizado: ${sanitizedDumpPath}`);

    success = true;
  } catch (error) {
    console.error("\n❌ Erro durante a cópia sanitizada:", error);
    console.error(
      `\n📁 Backups preservados em: ${workDir}`,
    );
    console.error(
      `   Para rollback do destino: mysql ${target.dbName} < ${targetBackupPath}`,
    );
    process.exitCode = 1;
  } finally {
    if (success) {
      if (!opts.keepTemp && databaseExists(mysqlConfig, tempDb)) {
        try {
          dropDatabase(mysqlConfig, tempDb, "limpar base temporária");
          console.log(`  🧹 Base temporária ${tempDb} eliminada.`);
        } catch (err) {
          console.warn(`  ⚠️  Não foi possível eliminar ${tempDb}:`, err);
        }
      }

      // Remover dump de origem (manter backup destino e sanitizado)
      try {
        if (existsSync(sourceDumpPath)) {
          rmSync(sourceDumpPath);
        }
      } catch {
        // ignorar
      }
    }

    await disconnectCentral();
  }
}

main().catch(async (error) => {
  console.error(error);
  await disconnectCentral();
  process.exit(1);
});

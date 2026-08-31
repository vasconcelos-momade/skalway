import { execSync, spawnSync } from "child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname } from "path";
import {
  assertNotProductionTarget,
  assertSafeDbIdentifier,
} from "./protected-databases";

export type MysqlCliConfig = {
  host: string;
  port: string;
  rootPassword: string;
  container?: string;
  useDocker: boolean;
};

export function loadMysqlCliConfig(): MysqlCliConfig {
  const container = process.env.MYSQL_CONTAINER || "phrx_mysql";
  const useDocker = detectDockerMysql(container);

  return {
    host: process.env.TENANT_DB_HOST || process.env.MYSQL_HOST || "phrx-db",
    port: process.env.TENANT_DB_PORT || process.env.MYSQL_PORT || "3306",
    rootPassword: process.env.MYSQL_ROOT_PASSWORD || "root_password",
    container,
    useDocker,
  };
}

function detectDockerMysql(container: string): boolean {
  if (process.env.TENANT_CLONE_USE_DOCKER === "0") {
    return false;
  }
  if (process.env.TENANT_CLONE_USE_DOCKER === "1") {
    return dockerContainerRunning(container);
  }
  // Preferir mysqldump do container MySQL 8 (evita bugs do client MariaDB com colunas geradas).
  if (dockerContainerRunning(container)) {
    return true;
  }
  return commandExists("mysqldump");
}

function dockerContainerRunning(container: string): boolean {
  try {
    const result = spawnSync("docker", ["inspect", "-f", "{{.State.Running}}", container], {
      encoding: "utf8",
    });
    return result.status === 0 && result.stdout.trim() === "true";
  } catch {
    return false;
  }
}

function commandExists(cmd: string): boolean {
  const result = spawnSync("which", [cmd], { encoding: "utf8" });
  return result.status === 0 && result.stdout.trim().length > 0;
}

function mysqlConnectionFlags(config: MysqlCliConfig): string[] {
  if (config.useDocker && config.container) {
    // MySQL 8 oficial (container phrx_mysql)
    return ["--ssl-mode=DISABLED"];
  }
  // MariaDB client (default-mysql-client no Debian)
  return ["--skip-ssl"];
}

function mysqlBaseArgs(config: MysqlCliConfig): string[] {
  if (config.useDocker && config.container) {
    return [
      "docker",
      "exec",
      config.container,
      "mysql",
      "-uroot",
      `-p${config.rootPassword}`,
      ...mysqlConnectionFlags(config),
    ];
  }
  return [
    "mysql",
    `-h${config.host}`,
    `-P${config.port}`,
    "-uroot",
    `-p${config.rootPassword}`,
    ...mysqlConnectionFlags(config),
  ];
}

function mysqldumpExtraArgs(config: MysqlCliConfig): string[] {
  const args = [
    ...mysqlConnectionFlags(config),
    "--single-transaction",
    "--routines",
    "--triggers",
    "--hex-blob",
    "--default-character-set=utf8mb4",
  ];
  // MySQL 8 oficial suporta set-gtid-purged; MariaDB client não.
  if (process.env.TENANT_CLONE_MYSQLDUMP_GTID === "1") {
    args.push("--set-gtid-purged=OFF");
  }
  if (process.env.TENANT_CLONE_MYSQLDUMP_COLUMN_STATS === "0") {
    args.push("--skip-column-statistics");
  }
  return args;
}

function mysqldumpBaseArgs(config: MysqlCliConfig): string[] {
  if (config.useDocker && config.container) {
    return [
      "docker",
      "exec",
      config.container,
      "mysqldump",
      "-uroot",
      `-p${config.rootPassword}`,
    ];
  }
  return [
    "mysqldump",
    `-h${config.host}`,
    `-P${config.port}`,
    "-uroot",
    `-p${config.rootPassword}`,
  ];
}

function runCommand(
  cmd: string[],
  options?: { input?: string; stdio?: "pipe" | "inherit"; dockerInteractive?: boolean },
): string {
  const finalCmd = [...cmd];
  if (options?.dockerInteractive && finalCmd[0] === "docker" && finalCmd[1] === "exec") {
    finalCmd.splice(2, 0, "-i");
  }

  const result = spawnSync(finalCmd[0], finalCmd.slice(1), {
    encoding: "utf8",
    input: options?.input,
    stdio: options?.stdio ?? "pipe",
    maxBuffer: 1024 * 1024 * 512,
  });

  if (result.status !== 0) {
    const stderr = result.stderr?.trim() || result.stdout?.trim() || "erro desconhecido";
    throw new Error(`Comando falhou (${finalCmd.join(" ")}): ${stderr}`);
  }

  return result.stdout ?? "";
}

export function databaseExists(config: MysqlCliConfig, dbName: string): boolean {
  const safe = assertSafeDbIdentifier(dbName);
  const output = runCommand([
    ...mysqlBaseArgs(config),
    "--batch",
    "--skip-column-names",
    "-e",
    `SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${safe}';`,
  ]);
  return output.trim() === "1";
}

export function createDatabase(
  config: MysqlCliConfig,
  dbName: string,
  operation: string,
): void {
  const safe = assertSafeDbIdentifier(dbName);
  assertNotProductionTarget(safe, operation);
  const appUser = (process.env.MYSQL_USER || "admin").replace(/'/g, "''");
  const appHost = (process.env.MYSQL_APP_HOST || "%").replace(/'/g, "''");

  runCommand([
    ...mysqlBaseArgs(config),
    "-e",
    `CREATE DATABASE IF NOT EXISTS \`${safe}\`; GRANT ALL PRIVILEGES ON \`${safe}\`.* TO '${appUser}'@'${appHost}'; FLUSH PRIVILEGES;`,
  ]);
}

export function dropDatabase(
  config: MysqlCliConfig,
  dbName: string,
  operation: string,
): void {
  const safe = assertSafeDbIdentifier(dbName);
  assertNotProductionTarget(safe, operation);
  runCommand([
    ...mysqlBaseArgs(config),
    "-e",
    `DROP DATABASE IF EXISTS \`${safe}\`;`,
  ]);
}

export function recreateDatabase(
  config: MysqlCliConfig,
  dbName: string,
  operation: string,
): void {
  const safe = assertSafeDbIdentifier(dbName);
  assertNotProductionTarget(safe, operation);
  dropDatabase(config, safe, operation);
  createDatabase(config, safe, operation);
}

/**
 * Dump consistente (read-only) — seguro para produção.
 * Usa --single-transaction para InnoDB sem bloquear escritas.
 */
export function dumpDatabase(
  config: MysqlCliConfig,
  dbName: string,
  outputPath: string,
): void {
  const safe = assertSafeDbIdentifier(dbName);
  mkdirSync(dirname(outputPath), { recursive: true });

  const dumpArgs = [
    ...mysqldumpBaseArgs(config),
    ...mysqldumpExtraArgs(config),
    safe,
  ];

  if (config.useDocker && config.container) {
    const sql = runCommand(dumpArgs);
    writeFileSync(outputPath, sql, "utf8");
  } else {
    execSync(`${dumpArgs.map(shellQuote).join(" ")} > ${shellQuote(outputPath)}`, {
      shell: "/bin/bash",
      stdio: "inherit",
      maxBuffer: 1024 * 1024 * 512,
    });
  }
}

export function restoreDatabase(
  config: MysqlCliConfig,
  dbName: string,
  sqlPath: string,
  operation: string,
): void {
  const safe = assertSafeDbIdentifier(dbName);
  assertNotProductionTarget(safe, operation);

  if (!existsSync(sqlPath)) {
    throw new Error(`Ficheiro SQL não encontrado: ${sqlPath}`);
  }

  const sql = readFileSync(sqlPath, "utf8");
  const useDocker = config.useDocker && !!config.container;

  runCommand([...mysqlBaseArgs(config), safe], {
    input: sql,
    dockerInteractive: useDocker,
  });
}

export async function countTablesAndRows(
  dbName: string,
): Promise<{ tables: number; rows: number; details: Array<{ table: string; rows: number }> }> {
  const { prismaCentralUnscoped } = await import(
    "../../../src/infrastructure/prisma/prisma-central.service"
  );
  const safe = assertSafeDbIdentifier(dbName);

  const tables = await (prismaCentralUnscoped as any).$queryRawUnsafe<
    Array<{ table_name: string; table_rows: bigint | number | null }>
  >(
    `SELECT TABLE_NAME AS table_name, TABLE_ROWS AS table_rows
     FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = ?
       AND TABLE_TYPE = 'BASE TABLE'
     ORDER BY TABLE_NAME`,
    safe,
  );

  const details = tables.map((t) => ({
    table: t.table_name,
    rows: Number(t.table_rows ?? 0),
  }));

  return {
    tables: details.length,
    rows: details.reduce((sum, t) => sum + t.rows, 0),
    details,
  };
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

export function buildTempSanitizeDbName(): string {
  const ts = Date.now();
  const rand = Math.random().toString(36).slice(2, 8);
  return `__phrx_clone_sanitize_${ts}_${rand}__`;
}

export function describeMysqlMode(config: MysqlCliConfig): string {
  return config.useDocker
    ? `docker exec ${config.container}`
    : `mysql@${config.host}:${config.port}`;
}

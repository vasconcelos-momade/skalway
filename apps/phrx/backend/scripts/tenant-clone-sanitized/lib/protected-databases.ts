/**
 * Proteção contra operações destrutivas em bases de produção.
 *
 * Toda operação DROP/DELETE/UPDATE/TRUNCATE no destino deve passar por
 * assertNotProductionTarget() antes de executar.
 */

const HARDCODED_PROTECTED = new Set([
  "skalway_central",
  "mysql",
  "information_schema",
  "performance_schema",
  "sys",
]);

function normalizeDbName(dbName: string): string {
  return String(dbName || "").trim().toLowerCase();
}

function loadProtectedFromEnv(): Set<string> {
  const raw = process.env.PROTECTED_DATABASES ?? "";
  const fromEnv = raw
    .split(",")
    .map((s) => normalizeDbName(s))
    .filter(Boolean);
  return new Set([...HARDCODED_PROTECTED, ...fromEnv]);
}

let cachedProtected: Set<string> | null = null;

export function getProtectedDatabases(): ReadonlySet<string> {
  if (!cachedProtected) {
    cachedProtected = loadProtectedFromEnv();
  }
  return cachedProtected;
}

export function isProtectedDatabase(dbName: string): boolean {
  const normalized = normalizeDbName(dbName);
  const protectedSet = getProtectedDatabases();

  if (protectedSet.has(normalized)) {
    return true;
  }

  // Padrões adicionais de produção
  if (
    normalized === "production" ||
    normalized === "prod" ||
    normalized.endsWith("_production") ||
    normalized.endsWith("_prod")
  ) {
    return true;
  }

  return false;
}

/**
 * Aborta imediatamente se a base for protegida (produção).
 * Usar antes de DROP, TRUNCATE, DELETE, UPDATE ou restore destrutivo.
 */
export function assertNotProductionTarget(
  database: string,
  operation: string,
): void {
  const dbName = String(database || "").trim();
  if (!dbName) {
    throw new Error(`[SEGURANÇA] Operação "${operation}": nome de base vazio.`);
  }

  if (isProtectedDatabase(dbName)) {
    throw new Error(
      `[SEGURANÇA FATAL] Operação destrutiva "${operation}" bloqueada na base protegida "${dbName}". ` +
        `Bases protegidas: ${[...getProtectedDatabases()].join(", ")}` +
        (process.env.PROTECTED_DATABASES
          ? ` (+ PROTECTED_DATABASES)`
          : ""),
    );
  }
}

/**
 * Garante que a base de origem nunca será alvo de escrita.
 * Apenas mysqldump (leitura) é permitido na origem.
 */
export function assertSourceIsReadOnly(
  sourceDb: string,
  targetDb: string,
  tempDb?: string,
): void {
  const source = String(sourceDb || "").trim();
  const target = String(targetDb || "").trim();
  const temp = tempDb ? String(tempDb).trim() : "";

  if (!source) {
    throw new Error("[SEGURANÇA] Base de origem não definida.");
  }
  if (!target) {
    throw new Error("[SEGURANÇA] Base de destino não definida.");
  }
  if (source === target) {
    throw new Error(
      `[SEGURANÇA FATAL] Origem e destino são a mesma base: "${source}".`,
    );
  }
  if (temp && source === temp) {
    throw new Error(
      `[SEGURANÇA FATAL] Origem e base temporária são iguais: "${source}".`,
    );
  }
  if (temp && target === temp) {
    throw new Error(
      `[SEGURANÇA FATAL] Destino e base temporária são iguais: "${target}".`,
    );
  }
}

export function assertSafeDbIdentifier(dbName: string): string {
  const name = String(dbName || "").trim();
  if (!/^[a-zA-Z0-9_]+$/.test(name) || name.length > 64) {
    throw new Error(`Nome de base MySQL inválido: ${dbName}`);
  }
  return name;
}

import { readFileSync, writeFileSync } from "fs";
import type { MysqlCliConfig } from "./mysql-cli";
import { assertSafeDbIdentifier } from "./protected-databases";

type ColumnMeta = {
  name: string;
  ordinal: number;
  generated: boolean;
};

type TableInsertFix = {
  table: string;
  columns: string[];
};

function parseSqlTupleValues(inner: string): string[] {
  const values: string[] = [];
  let i = 0;

  while (i < inner.length) {
    while (i < inner.length && (inner[i] === " " || inner[i] === "\n" || inner[i] === "\r" || inner[i] === "\t" || inner[i] === ",")) {
      i++;
    }
    if (i >= inner.length) break;

    const start = i;
    if (inner[i] === "'") {
      i++;
      while (i < inner.length) {
        if (inner[i] === "'" && inner[i + 1] === "'") {
          i += 2;
          continue;
        }
        if (inner[i] === "'") {
          i++;
          break;
        }
        i++;
      }
    } else {
      while (i < inner.length && inner[i] !== ",") i++;
    }

    values.push(inner.slice(start, i).trim());
    if (inner[i] === ",") i++;
  }

  return values;
}

function listTablesWithGeneratedInserts(sql: string): string[] {
  const tables = new Set<string>();
  const re = /INSERT INTO `([^`]+)` VALUES/gi;
  let match: RegExpExecArray | null;
  while ((match = re.exec(sql)) !== null) {
    tables.add(match[1]);
  }
  return [...tables];
}

async function loadTableColumns(
  config: MysqlCliConfig,
  dbName: string,
  tableName: string,
): Promise<ColumnMeta[]> {
  const { prismaCentralUnscoped } = await import(
    "../../../src/infrastructure/prisma/prisma-central.service"
  );

  const rows = await (prismaCentralUnscoped as any).$queryRawUnsafe<
    Array<{
      column_name: string;
      ordinal_position: number;
      generation_expression: string | null;
    }>
  >(
    `SELECT COLUMN_NAME AS column_name,
            ORDINAL_POSITION AS ordinal_position,
            GENERATION_EXPRESSION AS generation_expression
     FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = ?
       AND TABLE_NAME = ?
     ORDER BY ORDINAL_POSITION`,
    dbName,
    tableName,
  );

  return rows.map((row) => ({
    name: row.column_name,
    ordinal: Number(row.ordinal_position),
    generated:
      row.generation_expression != null &&
      String(row.generation_expression).trim() !== "",
  }));
}

function rewriteInsertBlock(
  sql: string,
  table: string,
  allColumns: ColumnMeta[],
): string {
  const generatedOrdinals = new Set(
    allColumns.filter((c) => c.generated).map((c) => c.ordinal),
  );
  const insertColumns = allColumns
    .filter((c) => !generatedOrdinals.has(c.ordinal))
    .map((c) => c.name);

  const headerRe = new RegExp(
    `INSERT INTO \`${table}\` VALUES\\s*`,
    "gi",
  );
  const match = headerRe.exec(sql);
  if (!match) return sql;

  const start = match.index;
  const valuesStart = match.index + match[0].length;
  let i = valuesStart;
  const tuples: string[] = [];

  while (i < sql.length) {
    while (i < sql.length && /\s/.test(sql[i])) i++;
    if (sql[i] !== "(") break;

    let depth = 0;
    const tupleStart = i;
    while (i < sql.length) {
      const ch = sql[i];
      if (ch === "'") {
        i++;
        while (i < sql.length) {
          if (sql[i] === "'" && sql[i + 1] === "'") {
            i += 2;
            continue;
          }
          if (sql[i] === "'") {
            i++;
            break;
          }
          i++;
        }
        continue;
      }
      if (ch === "(") depth++;
      if (ch === ")") {
        depth--;
        if (depth === 0) {
          i++;
          break;
        }
      }
      i++;
    }

    const inner = sql.slice(tupleStart + 1, i - 1);
    const parsed = parseSqlTupleValues(inner);
    const filtered = parsed.filter((_, idx) => !allColumns[idx]?.generated);
    tuples.push(`(${filtered.join(",")})`);

    while (i < sql.length && /\s/.test(sql[i])) i++;
    if (sql[i] === ",") {
      i++;
      continue;
    }
    break;
  }

  const end = i;
  const columnHeader = `INSERT INTO \`${table}\` (${insertColumns.map((c) => `\`${c}\``).join(", ")}) VALUES\n`;
  const newBlock = columnHeader + tuples.join(",\n");
  return sql.slice(0, start) + newBlock + sql.slice(end);
}

/**
 * Corrige dumps do client MariaDB que incluem colunas STORED GENERATED em
 * INSERT INTO `tabela` VALUES (...), o que o MySQL 8 rejeita no restore.
 */
export async function fixGeneratedColumnsInDump(
  config: MysqlCliConfig,
  dbName: string,
  sqlPath: string,
): Promise<number> {
  const safeDb = assertSafeDbIdentifier(dbName);
  let sql = readFileSync(sqlPath, "utf8");
  const tables = listTablesWithGeneratedInserts(sql);
  let fixedTables = 0;

  for (const table of tables) {
    const columns = await loadTableColumns(config, safeDb, table);
    const generated = columns.filter((c) => c.generated);
    if (generated.length === 0) continue;

    const before = sql;
    sql = rewriteInsertBlock(sql, table, columns);
    if (sql !== before) {
      fixedTables += 1;
      console.log(
        `  🔧 Dump corrigido: tabela \`${table}\` (${generated.length} coluna(s) gerada(s) removida(s))`,
      );
    }
  }

  if (fixedTables > 0) {
    writeFileSync(sqlPath, sql, "utf8");
  }

  return fixedTables;
}

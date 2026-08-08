import { execSync } from "child_process";
import { PrismaClient } from "../prisma/central/generated/central";
import { prismaCentral } from "../prisma/prisma-central.service";

function assertSafeDbIdentifier(dbName: string): string {
  const name = String(dbName || "").trim();
  if (!/^[a-zA-Z0-9_]+$/.test(name) || name.length > 64) {
    throw new Error(`Nome de base MySQL inválido: ${dbName}`);
  }
  return name;
}

export class MySqlManagementService {
  /**
   * Creates a new MySQL database for a tenant.
   * Usa root (como runMigrations) — o user da app só tem grants na BD central.
   */
  static async createDatabase(dbName: string) {
    const safeName = assertSafeDbIdentifier(dbName);
    console.log(`🛠 [MySQL] Criando banco de dados: ${safeName}`);
    const appUser = (process.env.MYSQL_USER || "admin").replace(/'/g, "''");
    const appHost = (process.env.MYSQL_APP_HOST || "%").replace(/'/g, "''");
    const { client, rootClient } = this.openRootClient();

    try {
      await client.$executeRawUnsafe(
        `CREATE DATABASE IF NOT EXISTS \`${safeName}\`;`,
      );
      await client.$executeRawUnsafe(
        `GRANT ALL PRIVILEGES ON \`${safeName}\`.* TO '${appUser}'@'${appHost}';`,
      );
      await client.$executeRawUnsafe(`FLUSH PRIVILEGES;`);
      console.log(`✅ [MySQL] Banco ${safeName} criado com sucesso.`);
      console.log(
        `🔐 [MySQL] Permissoes concedidas para ${appUser}@${appHost} em ${safeName}.`,
      );
    } catch (error) {
      console.error(`❌ [MySQL] Erro ao criar banco ${safeName}:`, error);
      throw new Error(`Falha ao criar banco de dados do tenant.`);
    } finally {
      if (rootClient) {
        await rootClient.$disconnect().catch(() => undefined);
      }
    }
  }

  /**
   * Renomeia uma base MySQL sem dump (RENAME TABLE + DROP).
   * Não altera dados das tabelas — só move objectos entre schemas.
   */
  static async renameDatabase(oldDbName: string, newDbName: string) {
    const from = assertSafeDbIdentifier(oldDbName);
    const to = assertSafeDbIdentifier(newDbName);
    if (from === to) {
      console.log(`ℹ️  [MySQL] renameDatabase: ${from} já está no nome alvo.`);
      return { renamed: false as const, from, to };
    }

    console.log(`🔁 [MySQL] Renomear base ${from} → ${to}`);
    const appUser = (process.env.MYSQL_USER || "admin").replace(/'/g, "''");
    const appHost = (process.env.MYSQL_APP_HOST || "%").replace(/'/g, "''");
    const { client, rootClient } = this.openRootClient();

    try {
      const fromExists = await this.schemaExists(client, from);
      if (!fromExists) {
        throw new Error(`Base de origem '${from}' não existe.`);
      }
      const toExists = await this.schemaExists(client, to);
      if (toExists) {
        throw new Error(`Base de destino '${to}' já existe.`);
      }

      await client.$executeRawUnsafe(`CREATE DATABASE \`${to}\`;`);

      const tables = await client.$queryRawUnsafe<Array<{ name: string }>>(
        `SELECT TABLE_NAME AS name
         FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = ?
         ORDER BY TABLE_NAME`,
        from,
      );

      if (tables.length > 0) {
        const clauses = tables
          .map(
            (row) =>
              `\`${from}\`.\`${row.name}\` TO \`${to}\`.\`${row.name}\``,
          )
          .join(", ");
        await client.$executeRawUnsafe(`RENAME TABLE ${clauses};`);
      }

      const leftover = await client.$queryRawUnsafe<
        Array<{ c: bigint | number }>
      >(
        `SELECT COUNT(*) AS c
         FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = ?`,
        from,
      );
      const remaining = Number(leftover[0]?.c ?? 0);
      if (remaining > 0) {
        throw new Error(
          `Ainda restam ${remaining} objecto(s) em '${from}' após RENAME TABLE.`,
        );
      }

      await client.$executeRawUnsafe(`DROP DATABASE \`${from}\`;`);
      await client.$executeRawUnsafe(
        `GRANT ALL PRIVILEGES ON \`${to}\`.* TO '${appUser}'@'${appHost}';`,
      );
      await client.$executeRawUnsafe(`FLUSH PRIVILEGES;`);

      console.log(`✅ [MySQL] Base renomeada: ${from} → ${to}`);
      return { renamed: true as const, from, to, tables: tables.length };
    } catch (error) {
      console.error(`❌ [MySQL] Erro ao renomear ${from} → ${to}:`, error);
      throw error instanceof Error
        ? error
        : new Error(`Falha ao renomear base ${from} → ${to}`);
    } finally {
      if (rootClient) {
        await rootClient.$disconnect().catch(() => undefined);
      }
    }
  }

  /**
   * Applies tenant Prisma schema for a new database.
   *
   * Não chama `prisma generate` aqui: em dev (`bun --watch`) regerar o client
   * altera ficheiros importados e reinicia o servidor a meio do registo do tenant,
   * interrompendo a criação de utilizadores na base tenant.
   * O client é gerado no entrypoint do container (docker-entrypoint.dev.sh).
   */
  static runMigrations(dbName: string) {
    const safeName = assertSafeDbIdentifier(dbName);
    console.log(`⚙️ [Prisma] Aplicando migrations no banco: ${safeName}`);

    const rootPassword = process.env.MYSQL_ROOT_PASSWORD;
    const dbUrl = `mysql://root:${rootPassword}@phrx-db:3306/${safeName}`;
    const env = { ...process.env, DATABASE_URL_TENANT: dbUrl };

    try {
      execSync(`DATABASE_URL_TENANT="${dbUrl}" bun run prisma:migrate:tenant`, {
        stdio: "inherit",
        env,
      });

      console.log(
        `✅ [Prisma] Schema tenant aplicado com sucesso em ${safeName}.`,
      );
    } catch (error) {
      console.error(
        `❌ [Prisma] Erro ao rodar migrations em ${safeName}:`,
        error,
      );
      throw new Error(`Falha ao aplicar migrations no banco do tenant.`);
    }
  }

  /**
   * Seeders estruturais apenas (roles, permissões, consumidor final, FNM, impostos).
   * Não inclui produtos, lotes, movimentações nem dados de demonstração.
   */
  static runStructuralSeed(dbName: string) {
    const safeName = assertSafeDbIdentifier(dbName);
    console.log(`🔐 [Seed] Seeders estruturais no banco: ${safeName}`);

    const rootPassword = process.env.MYSQL_ROOT_PASSWORD;
    const dbUrl = `mysql://root:${rootPassword}@phrx-db:3306/${safeName}`;

    try {
      execSync(`bun prisma/seed-tenant.ts`, {
        stdio: "inherit",
        env: { ...process.env, DATABASE_URL_TENANT: dbUrl },
      });
      console.log(`✅ [Seed] Seeders estruturais aplicados em ${safeName}.`);
    } catch (error) {
      console.error(
        `❌ [Seed] Erro ao semear dados estruturais em ${safeName}:`,
        error,
      );
      throw new Error(`Falha ao semear dados estruturais no banco do tenant.`);
    }
  }

  /** @deprecated Preferir runStructuralSeed — mantido para compatibilidade. */
  static runRolePermissionsSeed(dbName: string) {
    return this.runStructuralSeed(dbName);
  }

  private static openRootClient() {
    const rootPassword = process.env.MYSQL_ROOT_PASSWORD;
    const tenantHost =
      process.env.TENANT_DB_HOST || process.env.MYSQL_HOST || "phrx-db";
    const tenantPort =
      process.env.TENANT_DB_PORT || process.env.MYSQL_PORT || "3306";

    const rootClient =
      rootPassword != null && rootPassword !== ""
        ? new PrismaClient({
            datasources: {
              db: {
                url: `mysql://root:${encodeURIComponent(rootPassword)}@${tenantHost}:${tenantPort}/mysql`,
              },
            },
          })
        : null;
    return { client: rootClient ?? prismaCentral, rootClient };
  }

  private static async schemaExists(client: any, dbName: string) {
    const rows = await client.$queryRawUnsafe<Array<{ c: bigint | number }>>(
      `SELECT COUNT(*) AS c
       FROM information_schema.SCHEMATA
       WHERE SCHEMA_NAME = ?`,
      dbName,
    );
    return Number(rows[0]?.c ?? 0) > 0;
  }
}

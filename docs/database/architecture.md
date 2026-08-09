# Base de dados — arquitectura

## Duas camadas Prisma

| Schema | Path | BD |
|--------|------|-----|
| Central | `apps/phrx/backend/src/infrastructure/prisma/central/` | `skalway_central` |
| Tenant (filial) | `apps/phrx/backend/src/infrastructure/prisma/tenant/` | `phrx_tenant_*_branch_*` |

## Runtime

- `DATABASE_URL` → Central
- Credenciais / host de tenant via `TENANT_DB_*` + resolução dinâmica por branch (`x-tenant-id` / `x-branch-id`)
- `DATABASE_URL_TENANT` é sobretudo para comandos manuais (migrate/seed), não o caminho principal em runtime

## MySQL

- Imagem: `mysql:8.0`
- Init: `infra/docker/phrx/mysql/init.sql`
- TZ: `Africa/Maputo`

## Redis

- Usado por workers e filas (incl. print jobs)
- Prod: AOF (`appendonly yes`) + volume `phrx_redis_data`

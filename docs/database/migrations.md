# Migrations

## Central

```bash
# dentro do container ou com DATABASE_URL apontando a skalway_central
bun run …  # scripts Prisma no package.json do backend
docker exec phrx_backend bun run bootstrap:central   # migrations + seeders Central
```

Path: `apps/phrx/backend/src/infrastructure/prisma/central/migrations/`

## Tenant

Path: `apps/phrx/backend/src/infrastructure/prisma/tenant/migrations/`

Aplicar a **todas** as filiais (dev/ops):

```bash
# ver apps/phrx/backend/scripts/migrate-all-tenants.sh
docker exec phrx_backend bash scripts/migrate-all-tenants.sh
```

Criação de branch nova aplica migrations no use case de criação (não inventar fluxo paralelo).

## Produção (futuro)

1. Backup (`backup-mysql.sh --apply`)
2. Deploy nova imagem
3. Migrations Central
4. `migrate-all-tenants` (ou equivalente documentado no release)
5. Healthcheck

**NÃO** executar migrations remotas nesta fase.

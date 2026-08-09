# Multi-tenant — operação

Ver também [naming.md](./naming.md) e [architecture.md](./architecture.md).

## Isolamento

- Uma base MySQL por branch (filial)
- Metadados / billing / tenants na Central
- Scope estrito: `TENANT_SCOPE_STRICT=true` (bloqueia acesso Central sem contexto)

## Headers / contexto

O backend selecciona a BD da filial com base no contexto autenticado / headers de tenant-branch (ver módulos em `modules/central/tenants` e middlewares).

## Workers

Workers partilham `DATABASE_URL` (Central) + Redis; jobs de impressão usam a fila Redis `skalway:print-jobs` (nome efectivo no código do print-worker).

## Checklist novo tenant (dev)

1. Stack up + `bun run bootstrap:central`
2. Login SUPER_ADMIN
3. Criar tenant via API/UI
4. Confirmar BD `phrx_tenant_*` criada
5. Login owner da filial e smoke tests (`apps/phrx/scripts/…`)

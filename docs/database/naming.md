# Multi-tenant

## Padrão oficial

| Tipo | Naming |
|------|--------|
| Central | `skalway_central` |
| Branch / filial | `phrx_tenant_{tenantId}_branch_{branchId}` |

Exemplo: `phrx_tenant_1_branch_67676902934f4f27` (IDs reais vêm do código; o builder actual usa IDs numéricos — ver fonte abaixo).

## Fonte da verdade

`apps/phrx/backend/src/modules/central/tenants/domain/branch-db-name.ts`:

- `buildBranchDbName(tenantId, branchId)` → `phrx_tenant_${tid}_branch_${bid}`
- Validação / parse com regex `^phrx_tenant_\d+_branch_\d+$`

## Fluxo

1. Criar tenant (Central) → use case cria estrutura
2. Criar branch → cria BD `phrx_tenant_…`, corre migrations tenant, seed estrutural
3. Runtime resolve cliente Prisma da BD da branch activa

Scripts relacionados:

- `backend/scripts/rename-branch-databases.ts` — migração de nomes antigos
- `backend/scripts/migrate-all-tenants.sh` — migrations em todas as `phrx_tenant_*`

## Nomes legados

Padrões antigos possíveis: `tenant_*`, `pharm_*`, `branch_*`.

**Problema:** inconsistência com o padrão oficial e com scripts de backup (`phrx_tenant_*_branch_*`).

**Migração segura (proposta — NÃO executar automaticamente):**

1. Inventariar schemas: `SHOW DATABASES LIKE '%tenant%'`
2. Dry-run de `rename-branch-databases.ts`
3. Actualizar `Branch.dbName` na Central na mesma transacção lógica
4. Backup completo antes / depois
5. Validar login + POS numa filial piloto

Não correr rename em produção nesta fase.

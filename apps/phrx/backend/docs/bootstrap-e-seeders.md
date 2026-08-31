# Bootstrap e seeders PhRx

## Bootstrap Central

Comando oficial (idempotente — pode correr várias vezes):

```bash
# No host (redireciona automaticamente para o contentor se DATABASE_URL não existir)
bash apps/phrx/backend/scripts/bootstrap-central.sh
# ou: cd apps/phrx/backend/scripts && ./bootstrap-central.sh

# Equivalente directo no contentor
docker exec phrx_backend bun run bootstrap:central
```

O que faz, por ordem:

1. Migrations da Central (`prisma migrate deploy`)
2. Seeders da Central (`prisma/seed.ts`):
   - `SUPER_ADMIN` (`admin@skalway.com` / `admin123`) — **só se ainda não existir**
   - Planos (`starter`, `enterprise`; legado `base` desactivado)
   - Permissões centrais

Não cria Tenant nem Branch.

## Painel Admin — navegação

O shell SaaS (`PlatformMainShell`) usa secções Enterprise:

| Grupo | Itens |
|-------|--------|
| Dashboard | Dashboard |
| Clientes | Clientes, Filiais |
| Comercial | Planos, Assinaturas, Faturas, Pagamentos |
| Infraestrutura | Dispositivos, Sincronização |
| Segurança | Utilizadores, Auditoria |
| Configurações | Configurações |

- Marca: **PhRx Platform** / Super Administração  
- Pesquisa: `Pesquisar módulo...`  
- Mobile: Bottom Nav (Dashboard, Clientes, Financeiro, Utilizadores, Mais)  
- Formulário Novo Cliente: Side Sheet (não Dialog)

Fonte: `lib/modules/central/presentation/navigation/platform_nav_config.dart`

## Criar Cliente (UI Central)

Fluxo na app Flutter (`Novo cliente`):

1. Dialog permanece aberto com loading enquanto o backend provisiona.
2. Em sucesso: fecha, actualiza a lista e mostra toast.
3. Em erro: dialog fica aberto com a mensagem do backend.

Campos enviados a `POST /api/v1/central/tenants`:

| Grupo | Campos |
|-------|--------|
| Empresa | `nomeEmpresa`, `nuit` (9 dígitos), `email`, `endereco`, `telefone` |
| Tenant | `nomeTenant`/`slug`, `planSlug`, `status` (`trial`\|`ativo`) |
| Branch Matriz | `branchName`, `branchEndereco`, `branchContacto` (código gerado no backend) |
| Contas | admin local + `ownerUser` (conta central) |

`CreateTenantUseCase` cria atomicamente (com rollback soft-delete se a BD falhar): Tenant, settings, permissões, UserTenant, Subscription, Branch HQ, MySQL + migrations + seed estrutural.

Timeout do cliente HTTP para este POST: até 5 minutos (provisionamento longo).

## Fluxo esperado

```
bootstrap:central
    ↓
Login SUPER_ADMIN (UI ou API)
    ↓
Criar Tenant (UI / POST /central/tenants)
    ↓
CreateTenantUseCase
    ↓
Criar BD → migrations → seed-tenant (estrutural) → branch HQ
    ↓
Tenant pronto
```

Dados de demonstração **não** correm neste fluxo.

## Seeders do Tenant

| Script | npm | Quando | Conteúdo |
|--------|-----|--------|----------|
| `prisma/seed-tenant.ts` | `bun run seed:tenant <db>` | Automático na criação do tenant | Roles/permissões, Consumidor Final, categorias FNM, impostos, **terminais + caixas** |
| `prisma/seed-demo.ts` | `bun run seed:demo <db>` | Manual / opcional | Medicamentos ANARME, serviços, lotes, movimentações |
| `scripts/seed-fnm-categorias-all-tenants.ts` | `bun run seed:fnm-categorias:all` | Manual | Sincroniza categorias FNM em todos os tenants/filiais activos |
| `prisma/seed-all-tenant.ts` | — | Manual | Estrutural + demo |

Exemplos (com Docker Compose — `bun` corre **dentro** do contentor `phrx_backend`):

```bash
# Só estrutural (já feito pelo CreateTenantUseCase)
docker exec phrx_backend bun run seed:tenant phrx_tenant_1_branch_1

# Sincronizar categorias FNM em todos os tenants activos
docker exec phrx_backend bun run seed:fnm-categorias:all

# Sincronizar categorias FNM num tenant específico
docker exec phrx_backend bun scripts/seed-fnm-categorias-all-tenants.ts phrx_tenant_1_branch_1

# Demo (pode demorar 20–30 min)
docker exec phrx_backend bun run seed:demo phrx_tenant_1_branch_1
```

## Scripts de desenvolvimento

| Script | Função |
|--------|--------|
| `scripts/setup-dev-environment.sh` | Sobe compose → bootstrap Central → cria tenant via API → valida login |
| `scripts/create-tenant-and-seed.sh` | Bootstrap Central → cria tenant → valida login (containers já up) |
| `scripts/test-tenant-creation.sh` | Smoke de criação; demo só com `RUN_DEMO_SEED=1` |

Credenciais padrão após bootstrap:

- SUPER_ADMIN: `admin@skalway.com` / `admin123`

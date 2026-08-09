# PhRx

ERP farmacêutico Skalway (multi-tenant).

```
phrx/
├── backend/     # Bun + Prisma (API :3300, workers)
├── app/         # Flutter (web / desktop / mobile)
├── scripts/     # smoke / setup
└── docs/        # notas de produto (VM Flutter, etc.)
```

Ops (Compose, `.env`, nginx host, scripts de deploy) estão no monorepo:

- [`infra/`](../../infra/README.md)
- [`docs/`](../../docs/README.md)

## O que é

- API Bun (`Bun.serve`) + Prisma (Central + Tenant)
- MySQL multi-tenant + Redis + worker + print-worker
- Cliente Flutter

## Subir DEV

```bash
cd ../../infra/docker/phrx
cp -n .env.example .env
docker compose -f docker-compose.dev.yml up --build
```

| Serviço | URL / porto |
|---------|-------------|
| Backend | http://localhost:4001 (`/api/v1/health`) |
| Nginx | http://localhost:8280 |
| MySQL | localhost:3312 |
| Redis | localhost:6380 |
| phpMyAdmin | http://localhost:8686 |

Containers: `phrx_backend`, `phrx_backend_worker`, `phrx_backend_print_worker`, `phrx_mysql`, `phrx_redis`.

Guia: [docs/deployment/development.md](../../docs/deployment/development.md).

## Bootstrap Central

```bash
docker exec phrx_backend bun run bootstrap:central
```

Idempotente: migrations + seeders Central + `SUPER_ADMIN` (só se não existir).
Detalhes: [`backend/docs/bootstrap-e-seeders.md`](./backend/docs/bootstrap-e-seeders.md)

Fluxo: **bootstrap Central → login SUPER_ADMIN → criar Tenant (UI)** → BD `phrx_tenant_{id}_branch_{id}` + migrations + seed estrutural.

## App (Flutter)

```bash
cd app
flutter run
```

Variáveis: `API_BASE_URL`, `API_CLOUD_URL` — ver [`app/.env.example`](./app/.env.example).

Build web (futuro prod):

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api-phrx.skalway.com \
  --dart-define=API_CLOUD_URL=https://api-phrx.skalway.com
```

## Banco / Redis

- Central: `skalway_central`
- Filiais: `phrx_tenant_{tenantId}_branch_{branchId}`
- Docs: [docs/database/](../../docs/database/naming.md)

## Futura produção

Domínios: `phrx.skalway.com` + `api-phrx.skalway.com`.
Compose: `infra/docker/phrx/docker-compose.prod.yml`.
**Não fazer deploy agora** — ver [docs/deployment/production.md](../../docs/deployment/production.md).

## Testes

A partir de `apps/phrx` (stack a correr):

```bash
export LOGIN_EMAIL='dono....@demo.com'
export LOGIN_PASSWORD='123456'
export TENANT_DB='phrx_tenant_…'

bash scripts/smoke-api-v1-validation.sh
bash scripts/setup-dev-environment.sh
```

## Docs

| Tema | Link |
|------|------|
| Arquitectura | [docs/architecture/overview.md](../../docs/architecture/overview.md) |
| Infra / Docker | [docs/infrastructure/docker.md](../../docs/infrastructure/docker.md) · [INFRA.md](./INFRA.md) |
| Bootstrap | [backend/docs/bootstrap-e-seeders.md](./backend/docs/bootstrap-e-seeders.md) |
| Billing | [backend/docs/api-central-billing.md](./backend/docs/api-central-billing.md) |

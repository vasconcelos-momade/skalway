# PhRx

ERP farmacêutico Skalway.

```
phrx/
├── backend/     # servidor (Bun + Prisma)
├── app/         # cliente
├── scripts/     # testes e setup
└── docs/
```

## Subir ambiente

Ops (compose, `.env`, nginx, mysql init) estão em **`infra/`**, não aqui:

```bash
cd ../../infra/docker/phrx
docker compose -f docker-compose.dev.yml up --build
```

| Serviço | URL / porto |
|---------|-------------|
| Backend | http://localhost:4001 (`/api/v1/health`) |
| Nginx | http://localhost:8280 |
| MySQL | localhost:3312 |
| phpMyAdmin | http://localhost:8686 |

Containers: `phrx_backend`, `phrx_backend_worker`, `phrx_mysql`, `phrx_redis`.

## Bootstrap Central

```bash
docker exec phrx_backend bun run bootstrap:central
```

Idempotente: migrations + seeders da Central + `SUPER_ADMIN` (só se não existir).  
Detalhes: [`backend/docs/bootstrap-e-seeders.md`](./backend/docs/bootstrap-e-seeders.md)

Fluxo: **bootstrap Central → login SUPER_ADMIN → criar Tenant (UI)** → `CreateTenantUseCase` aplica BD, migrations e seed estrutural (inclui terminais). Demo (ANARME, etc.) é opcional via `bun run seed:demo <db>`.

## App

```bash
cd app
flutter run
```

## Testes

A partir de `apps/phrx` (stack a correr):

```bash
export LOGIN_EMAIL='dono....@demo.com'
export LOGIN_PASSWORD='123456'
export TENANT_DB='tenant_farmacia_....'

bash scripts/smoke-api-v1-validation.sh
bash scripts/test-login-and-products.sh
bash scripts/test-authorization.sh
bash scripts/test-owner-api.sh
bash scripts/test-pos-flow.sh
bash scripts/test-pos-draft-cart.sh
bash scripts/test-pos-owner.sh
bash scripts/test-stock-entry.sh
```

Setup completo (compose + bootstrap Central + tenant via API + validar login):

```bash
bash scripts/setup-dev-environment.sh
```

## Docs detalhadas

- Bootstrap / seeders: [`backend/docs/bootstrap-e-seeders.md`](./backend/docs/bootstrap-e-seeders.md)
- Ops: [`INFRA.md`](./INFRA.md) · [`../../infra/README.md`](../../infra/README.md)
- Billing API: [`backend/docs/api-central-billing.md`](./backend/docs/api-central-billing.md)
- Schema billing: [`backend/docs/schema-central-billing.md`](./backend/docs/schema-central-billing.md)

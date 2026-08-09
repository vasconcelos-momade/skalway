# Arquitectura — overview

Skalway PhRx é um ERP farmacêutico multi-tenant.

## Stack (fonte da verdade no código)

| Camada | Tecnologia |
|--------|------------|
| API | Bun (`Bun.serve`) + router próprio — porta interna **3300** |
| ORM | Prisma (schema Central + schema Tenant) |
| BD | MySQL 8 |
| Fila / cache | Redis 7 |
| Workers | `worker` (jobs gerais) + `worker:print` (impressão) |
| Cliente | Flutter (web, desktop, mobile) |

> Nota: referências históricas a Elysia não se aplicam ao código actual.

## Componentes

```
apps/phrx/backend/   → API + workers
apps/phrx/app/       → cliente Flutter
infra/docker/phrx/   → Compose DEV/PROD
infra/nginx/         → Nginx de referência (host)
services/            → identity, billing, …
```

## Domínios (padrão oficial futuro)

| Função | Hostname |
|--------|----------|
| Frontend | `https://phrx.skalway.com` |
| API | `https://api-phrx.skalway.com` |

Nomes antigos (`pharm.skalway.com`, `api.skalway.com`) são legado — não usar em docs novas.

## Fluxo de dados (dev)

```
Flutter / curl → localhost:4001 → container phrx_backend:3300
                      ↓
              MySQL (phrx_mysql) + Redis (phrx_redis)
```

## Fluxo de dados (produção planeada)

Ver [production.md](./production.md) e [networking.md](./networking.md).

## Multi-tenant

- Central: `skalway_central`
- Filial: `phrx_tenant_{tenantId}_branch_{branchId}`

Detalhes: [docs/database/multi-tenant.md](../database/multi-tenant.md).

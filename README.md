# Skalway — Monorepo

Plataforma multi-produto Skalway.

```
skalway/
├── apps/                     # produtos (código de negócio)
│   ├── website/              # landing / marketing
│   ├── phrx/
│   │   ├── backend/          # Bun + Prisma
│   │   └── app/              # Flutter
│   ├── gastro/
│   └── retail/
├── services/                 # identity, billing, …
├── infra/                    # Docker, nginx, scripts, Cloudflare (planeamento)
└── docs/                     # arquitectura, deploy, ops (produção futura)
```

Princípio: pastas nomeiam **função** (`backend`, `app`, `identity`), não tecnologia.

## PhRx (desenvolvimento)

```bash
cd infra/docker/phrx
cp -n .env.example .env
docker compose -f docker-compose.dev.yml up --build
```

| | |
|--|--|
| API | http://localhost:4001 (`/api/v1/health`) |
| App | `cd apps/phrx/app && flutter run` |
| Docs produto | [apps/phrx/README.md](./apps/phrx/README.md) |
| Docs ops | [docs/README.md](./docs/README.md) · [infra/README.md](./infra/README.md) |

## Domínios alvo (PhRx)

| Host | Destino |
|------|---------|
| `phrx.skalway.com` | Flutter Web → `/var/www/phrx` |
| `api.phrx.skalway.com` | Nginx → `127.0.0.1:4001` → container |

Produção está **preparada** no repo (compose prod, nginx ref, scripts dry-run) — **não** aplicar na VPS automaticamente. Ver [docs/deployment/production.md](./docs/deployment/production.md).

## Extração de serviços

| Serviço | Estado |
|---------|--------|
| **identity** | JWT + lockout em `@skalway/identity` |
| **billing** | Integridade/pricing em `@skalway/billing` |
| notifications | stub |
| audit | stub |

# Skalway — Monorepo

Plataforma multi-produto Skalway.

```
skalway/
├── apps/                     # produtos (código de negócio)
│   ├── website/              # landing / marketing
│   ├── phrx/
│   │   ├── backend/          # servidor do produto
│   │   └── app/              # cliente (UI)
│   ├── gastro/
│   │   ├── backend/
│   │   └── app/
│   └── retail/
│       ├── backend/
│       └── app/
├── services/                 # capacidades partilhadas
│   ├── identity/
│   ├── billing/
│   ├── notifications/
│   └── audit/
└── infra/                    # operação, deploy, produção (sem negócio)
    ├── docker/               # compose e artefactos por produto
    ├── nginx/                # rotas por domínio
    └── monitoring/
```

Princípio: pastas nomeiam **função** (`backend`, `app`, `identity`), não tecnologia (`api`, `flutter`, `bun`).

## PhRx

```bash
cd infra/docker/phrx
docker compose -f docker-compose.dev.yml up --build
```

- Backend: `http://localhost:4001`
- App: `cd apps/phrx/app && flutter run`

## Domínios alvo

| Host | Destino |
|------|---------|
| skalway.com | website |
| phrx.skalway.com | PhRx app |
| api.phrx.skalway.com | PhRx backend |
| api.gastro.skalway.com | Gastro backend |

## Extração de serviços

| Serviço | Estado |
|---------|--------|
| **identity** | JWT + lockout em `@skalway/identity` |
| **billing** | Integridade/pricing em `@skalway/billing` |
| notifications | stub |
| audit | stub |

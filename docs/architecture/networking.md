# Networking

## Rede Docker

- Nome: `phrx_net` (bridge)
- Serviços falam entre si por hostname Compose (`phrx-db`, `redis`, `phrx-backend`)

## Exposição

### DEV (`docker-compose.dev.yml`)

| Serviço | Host |
|---------|------|
| API | `*:4001` → 3300 |
| Nginx local | `*:8280` → 80 |
| MySQL | `*:3312` → 3306 |
| Redis | `*:6380` → 6379 |
| phpMyAdmin | `*:8686` |

### PROD (`docker-compose.prod.yml`)

| Serviço | Host |
|---------|------|
| API | **apenas** `127.0.0.1:4001` → 3300 |
| MySQL / Redis | sem `ports:` |

## Path da API

Health: `GET /api/v1/health`
Prefixo de negócio: `/api/v1/...`

## CORS (produção)

Compose prod define:

```
CORS_ALLOWED_ORIGINS=https://phrx.skalway.com
```

Implementação: `apps/phrx/backend/src/shared/http/middlewares.ts` (`CORS_ALLOWED_ORIGINS`).

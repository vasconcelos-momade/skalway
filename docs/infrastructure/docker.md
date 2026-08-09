# Docker

## Localização

```
infra/docker/phrx/
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── docker-compose.yml          # LEGACY / DEPRECATED — preferir .dev / .prod
├── .env.example
├── mysql/init.sql
└── nginx/default.conf          # proxy local DEV (uploads)
```

Imagens:

- DEV: `apps/phrx/backend/Dockerfile.dev`
- PROD: `apps/phrx/backend/Dockerfile`

## Serviços (reais no projeto)

| Serviço Compose | Container | Função |
|-----------------|-----------|--------|
| `phrx-backend` | `phrx_backend` | API Bun :3300 |
| `phrx-backend-worker` | `phrx_backend_worker` | `bun run worker` |
| `phrx-backend-print-worker` | `phrx_backend_print_worker` | `bun run worker:print` |
| `phrx-db` | `phrx_mysql` | MySQL 8 |
| `redis` | `phrx_redis` | Redis 7 |
| `nginx` | `phrx_nginx` | só DEV |
| `adminer` | `phrx_phpmyadmin` | só DEV |

## Network / volumes

- Network: `phrx_net`
- Volumes prod: `phrx_mysql_data`, `phrx_redis_data`
- Volumes dev: `phrx_mysql`, `phrx_redis_data`, cache de `node_modules` / Prisma generated

## Healthchecks (prod)

- MySQL: `mysqladmin ping`
- Redis: `redis-cli ping`
- Backend: `GET http://127.0.0.1:3300/api/v1/health`

## Restart

Prod: `unless-stopped`. Dev: `always`.

## Secrets

Via `env_file: ./.env` — **nunca** commitado. Modelo: `.env.example`.
Permissão futura: `chmod 600 .env`.

## Build

```bash
./infra/scripts/build.sh --dry-run
./infra/scripts/build.sh --backend-only
```

## Logs

Prod Compose: driver `json-file` com rotação (`max-size` / `max-file`).

## Segurança

Em produção **não** expor `3306` nem `6379` na Internet. API só em loopback `127.0.0.1:4001`.

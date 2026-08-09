# Desenvolvimento

## Pré-requisitos

- Docker + Compose
- (opcional) Flutter SDK, Bun local

## Subir stack

```bash
cd infra/docker/phrx
cp -n .env.example .env
docker compose -f docker-compose.dev.yml up --build
```

| Serviço | URL |
|---------|-----|
| API | http://localhost:4001/api/v1/health |
| Nginx | http://localhost:8280 |
| MySQL | localhost:3312 |
| Redis | localhost:6380 |
| phpMyAdmin | http://localhost:8686 |

## Bootstrap Central

```bash
docker exec phrx_backend bun run bootstrap:central
```

## Flutter

```bash
cd apps/phrx/app
flutter run
# ou com API na LAN:
# flutter run --dart-define=API_BASE_URL=http://<IP>:4001
```

Defaults de API: ver `apps/phrx/app/.env.example`.

## Smoke

```bash
cd apps/phrx
bash scripts/setup-dev-environment.sh   # opcional, fluxo completo
bash scripts/smoke-api-v1-validation.sh
```

## Scripts infra (locais)

```bash
./infra/scripts/bootstrap.sh --dry-run
./infra/scripts/healthcheck.sh
./infra/scripts/check-stack.sh
```

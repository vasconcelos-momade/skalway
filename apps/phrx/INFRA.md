# Ops / deploy PhRx

Compose, nginx local, MySQL init e `.env` vivem em:

```
infra/docker/phrx/
```

```bash
cd ../../infra/docker/phrx
docker compose -f docker-compose.dev.yml up --build
```

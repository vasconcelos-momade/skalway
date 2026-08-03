# Ops / deploy PhRx

Compose, nginx local, MySQL init e `.env` vivem em:

```
infra/docker/phrx/
```

```bash
cd ../../infra/docker/phrx
docker compose -f docker-compose.dev.yml up --build
```

Após o stack estar up, bootstrap da Central:

```bash
docker exec phrx_backend bun run bootstrap:central
```

Ver fluxo completo (Central vs Tenant, seed estrutural vs demo): [`backend/docs/bootstrap-e-seeders.md`](./backend/docs/bootstrap-e-seeders.md)

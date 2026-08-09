# Ops / deploy PhRx

Compose, nginx local, MySQL init e `.env` vivem em:

```
infra/docker/phrx/
```

Documentação: [`docs/`](../../docs/README.md) · scripts: [`infra/scripts/`](../../infra/scripts/).

```bash
cd ../../infra/docker/phrx
docker compose -f docker-compose.dev.yml up --build
```

Após o stack estar up, bootstrap da Central:

```bash
docker exec phrx_backend bun run bootstrap:central
```

Produção (preparada, não aplicar agora): `docker-compose.prod.yml` · [docs/deployment/production.md](../../docs/deployment/production.md).

Ver fluxo completo (Central vs Tenant, seed estrutural vs demo): [`backend/docs/bootstrap-e-seeders.md`](./backend/docs/bootstrap-e-seeders.md)

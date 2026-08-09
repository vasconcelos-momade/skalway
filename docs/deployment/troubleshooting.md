# Troubleshooting

## API não responde em :4001

1. `docker ps` — `phrx_backend` running?
2. `docker logs phrx_backend --tail 100`
3. `curl -v http://127.0.0.1:4001/api/v1/health`
4. MySQL healthy? Redis up?

## Erros Cloudflare 521 / 522 / 525 / 526

Ver [docs/infrastructure/cloudflare.md](../infrastructure/cloudflare.md).

## CORS no browser

Confirmar `CORS_ALLOWED_ORIGINS` inclui `https://phrx.skalway.com` (prod) ou origem Flutter web local.

## Tenant / BD em falta

- Naming: `phrx_tenant_{id}_branch_{id}`
- `Branch.dbName` na Central alinhado
- Scripts `rename-branch-databases.ts` só com backup

## Print jobs parados

- Container `phrx_backend_print_worker`
- Redis acessível
- Logs do print-worker

## Prisma client

Em DEV, volumes de generated Prisma — rebuild se schemas mudaram:

```bash
docker compose -f docker-compose.dev.yml up --build
```

# Arquitectura — produção (planeada)

**Estado:** documentação / preparação no repositório.
**NÃO aplicar automaticamente na VPS.**

## Diagrama

```
                 INTERNET
                    │
                    ▼
             ┌─────────────┐
             │ Cloudflare  │  Full Strict · Proxy · WAF
             └──────┬──────┘
                    │ HTTPS
                    ▼
             ┌─────────────┐
             │    Nginx    │  Ubuntu host :80 / :443
             └──────┬──────┘
          ┌─────────┴─────────┐
          ▼                   ▼
   phrx.skalway.com    api.phrx.skalway.com
          │                   │
          ▼                   ▼
   /var/www/phrx         127.0.0.1:4001
                              │
                              ▼
                      Docker network phrx_net
                              │
         ┌────────────────────┼─────────────────┐
         ▼                    ▼                 ▼
   phrx_backend          phrx_mysql        phrx_redis
         │
    ┌────┴────────┐
    ▼             ▼
 worker      print-worker
```

## Mapeamento de portas

| Público | Host | Container |
|---------|------|-----------|
| HTTPS API | `127.0.0.1:4001` | `phrx_backend:3300` |
| MySQL | **não publicado** | `phrx-db:3306` |
| Redis | **não publicado** | `redis:6379` |

Compose de referência: `infra/docker/phrx/docker-compose.prod.yml`.

## Checklist futuro (ordem)

Ver [docs/deployment/production.md](../deployment/production.md).

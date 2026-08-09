# Produção — guia futuro

**PREPARADO apenas. NÃO executar deploy agora.**

Preparação da VPS (directórios, secrets, pre-flight):
→ **[vps-preparation.md](./vps-preparation.md)**

## Artefactos PROD BUILD (sem deploy)

| Artefacto | Local / tag |
|-----------|-------------|
| Imagem backend + workers + print-worker | `skalway-phrx-backend:prod` |
| Flutter Web | `apps/phrx/app/build/web/` → futuro `/var/www/phrx` |
| Flutter Linux (desktop) | `apps/phrx/app/build/linux/x64/release/bundle/` |
| APK | requer Android SDK |
| Compose | `infra/docker/phrx/docker-compose.prod.yml` → VPS `/opt/skalway/` |
| Nginx ref | `infra/nginx/skalway.conf` → `/etc/nginx/sites-available/skalway.conf` |
| Env template | `infra/docker/phrx/.env.example` → `/opt/skalway/.env` (`chmod 600`) |

```bash
./infra/scripts/build.sh --backend-only
API_BASE_URL=https://api.phrx.skalway.com ./infra/scripts/build.sh --web-only
```

## Layout runtime na VPS

```
/opt/skalway/{.env,docker-compose.prod.yml,backups/mysql,logs,apps/phrx}
/var/www/phrx/
/etc/nginx/sites-{available,enabled}/skalway.conf
/etc/ssl/cloudflare/{origin.crt,origin.key}
```

## Ordem recomendada

### A — Preparação (sem app a correr)

1. Provisionar VPS Ubuntu + SSH
2. Instalar Docker, Compose, Nginx, UFW (manual)
3. Criar directórios oficiais ([vps-preparation.md](./vps-preparation.md))
4. Colocar compose + `.env` (`chmod 600`) + Origin CA
5. Configurar Nginx (ficheiros) — **sem** tráfego real ainda se DNS não estiver pronto
6. DNS Cloudflare `phrx` + `api.phrx` Proxied + SSL Full Strict (manual)
7. Correr **`./infra/scripts/vps-preflight.sh`** na VPS — zero `[FAIL]`

### B — Deploy (etapa seguinte — NÃO agora)

8. Carregar imagem `skalway-phrx-backend:prod`
9. `docker compose -f docker-compose.prod.yml --env-file .env up -d`
10. Migrations Central + tenants
11. Publicar Flutter Web → `/var/www/phrx`
12. `healthcheck.sh` / `check-stack.sh --full`
13. Agendar `BACKUP_DIR=/opt/skalway/backups/mysql backup-mysql.sh`
14. Monitorização

## Compose

```bash
cd /opt/skalway   # ou infra/docker/phrx no monorepo
docker compose -f docker-compose.prod.yml --env-file .env config
# futuro: docker compose -f docker-compose.prod.yml --env-file .env up -d
```

## Scripts

| Script | Uso |
|--------|-----|
| `vps-preflight.sh` | Verificar VPS **antes** do deploy (report-only) |
| `deploy.sh` | Dry-run por omissão; `--apply` só com confirmação |
| `healthcheck.sh` | Após containers up |
| `backup-mysql.sh` | Backups Central + `phrx_tenant_*` |

```bash
./infra/scripts/vps-preflight.sh --dry-run
./infra/scripts/deploy.sh           # dry-run
# NÃO: deploy.sh --apply / restore --apply / rollback --apply nesta fase
```

## Domínios

- Frontend: `https://phrx.skalway.com` → `/var/www/phrx`
- API: `https://api.phrx.skalway.com` → `127.0.0.1:4001`

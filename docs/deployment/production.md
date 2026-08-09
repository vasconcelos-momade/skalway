# Produção — guia futuro

**PREPARADO apenas. NÃO executar deploy agora.**

Preparação da VPS (directórios, secrets, pre-flight):
→ **[vps-preparation.md](./vps-preparation.md)**

## Flutter Web (build local → VPS)

O Flutter **não** corre na VPS. Build na máquina de desenvolvimento; a VPS só recebe estáticos em `/var/www/phrx`.

```
Local apps/phrx/app
        ↓  ./infra/scripts/build-web.sh
build/web
        ↓  rsync/SSH (deploy-web.sh)
VPS /var/www/phrx
        ↓  Nginx
https://phrx.skalway.com
```

API: `https://api.phrx.skalway.com` → `127.0.0.1:4001` (Docker; fluxo separado).

### Comandos

```bash
# Build local (sem flutter clean / pub get)
./infra/scripts/build-web.sh
# opcional: ./infra/scripts/build-web.sh --clean

# Deploy para VPS (requer SSH + rsync)
VPS_HOST=SEU_HOST \
VPS_USER=vasco \
./infra/scripts/deploy-web.sh

# Testes HTTPS
./infra/scripts/test-web.sh

# Fluxo completo (build + deploy + testes)
VPS_HOST=SEU_HOST VPS_USER=vasco \
  ./infra/scripts/deploy-web-production.sh

# Com commit/push explícito antes do deploy
VPS_HOST=SEU_HOST VPS_USER=vasco \
  ./infra/scripts/deploy-web-production.sh --commit
```

`dart-define` de produção: `ENVIRONMENT=prod`, `API_BASE_URL` / `API_CLOUD_URL` = `https://api.phrx.skalway.com`.

O deploy Web **não** executa `docker compose`, Prisma, npm nem Flutter na VPS.

## Artefactos PROD BUILD (sem deploy)

| Artefacto | Local / tag |
|-----------|-------------|
| Imagem backend + workers + print-worker | `skalway-phrx-backend:prod` |
| Flutter Web | `apps/phrx/app/build/web/` → futuro `/var/www/phrx` |
| Flutter Linux (desktop) | `apps/phrx/app/build/linux/x64/release/bundle/` |
| APK | requer Android SDK |
| Compose | `infra/docker/phrx/docker-compose.prod.yml` (no monorepo; VPS: `/opt/skalway-repo/…`) |
| Nginx ref | `infra/nginx/skalway.conf` → `/etc/nginx/sites-available/skalway.conf` |
| Env template | `infra/docker/phrx/.env.example` → `infra/docker/phrx/.env` (`chmod 600`) |

```bash
./infra/scripts/build.sh --backend-only
API_BASE_URL=https://api.phrx.skalway.com ./infra/scripts/build.sh --web-only
```

## Layout na VPS (multi-app)

```
/opt/skalway-repo/                         # REPO_ROOT — monorepo
  infra/docker/phrx/docker-compose.prod.yml
  infra/docker/phrx/.env

/opt/skalway/                              # SKALWAY_ROOT — runtime
  backups/mysql/
  logs/

/var/www/phrx/
/etc/nginx/sites-{available,enabled}/skalway.conf
/etc/ssl/cloudflare/{origin.crt,origin.key}
```

Não copiar o compose para `/opt/skalway/`. Cada app tem o seu compose sob `infra/docker/<app>/`.

## Ordem recomendada

### A — Preparação (sem app a correr)

1. Provisionar VPS Ubuntu + SSH
2. Instalar Docker, Compose, Nginx, UFW (manual)
3. Clone em `/opt/skalway-repo` + dirs runtime ([vps-preparation.md](./vps-preparation.md))
4. `.env` em `infra/docker/phrx/` (`chmod 600`) + Origin CA
5. Configurar Nginx (ficheiros) — **sem** tráfego real ainda se DNS não estiver pronto
6. DNS Cloudflare `phrx` + `api.phrx` Proxied + SSL Full Strict (manual)
7. Correr **`./infra/scripts/vps-preflight.sh`** na VPS — zero `[FAIL]`

### B — Deploy (etapa seguinte — NÃO agora)

8. Carregar imagem `skalway-phrx-backend:prod`
9. `cd /opt/skalway-repo/infra/docker/phrx && docker compose -f docker-compose.prod.yml --env-file .env up -d --build`
   (`phrx-migrate` aplica `prisma migrate deploy` no Central antes do backend)
10. Migrations tenant (filiais), se necessário — Central já via `phrx-migrate`
11. Publicar Flutter Web → `/var/www/phrx` (`./infra/scripts/deploy-web.sh`)
12. `./infra/scripts/test-web.sh` + `healthcheck.sh` / `check-stack.sh --full`
13. Agendar `BACKUP_DIR=/opt/skalway/backups/mysql backup-mysql.sh`
14. Monitorização

## Compose

```bash
cd /opt/skalway-repo/infra/docker/phrx
docker compose -f docker-compose.prod.yml --env-file .env config
# futuro: docker compose -f docker-compose.prod.yml --env-file .env up -d
```

## Scripts

| Script | Uso |
|--------|-----|
| `vps-preflight.sh` | Verificar VPS **antes** do deploy (report-only) |
| `build-web.sh` | Flutter Web release (local) |
| `deploy-web.sh` | rsync build/web → `/var/www/phrx` |
| `test-web.sh` | HTTPS frontend + API health |
| `deploy-web-production.sh` | Orquestra build → (commit?) → deploy → testes |
| `deploy.sh` | Compose prod backend (dry-run por omissão) |
| `healthcheck.sh` | Após containers up |
| `backup-mysql.sh` | Backups Central + `phrx_tenant_*` |

```bash
REPO_ROOT=/opt/skalway-repo SKALWAY_ROOT=/opt/skalway ./infra/scripts/vps-preflight.sh --dry-run
./infra/scripts/deploy.sh           # dry-run
# NÃO: deploy.sh --apply / restore --apply / rollback --apply nesta fase
```

## Domínios

- Frontend: `https://phrx.skalway.com` → `/var/www/phrx`
- API: `https://api.phrx.skalway.com` → `127.0.0.1:4001`

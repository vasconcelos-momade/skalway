# Preparação da VPS — Skalway PhRx

**Estado:** documentação + script de pre-flight no repositório.
**NÃO** executar nesta fase contra a VPS real. A próxima etapa será correr o pre-flight **na** VPS.

Não fazer deploy. Não iniciar a aplicação em produção. Não alterar Cloudflare/DNS a partir deste documento sem processo manual separado.

## Arquitectura oficial

```
Cloudflare (Full Strict, Proxied)
  ↓
Nginx (host Ubuntu :80 / :443)
  ↓
phrx.skalway.com      → /var/www/phrx          (Flutter Web)
api.phrx.skalway.com  → 127.0.0.1:4001         (API)
  ↓
Docker network phrx_net
  ├── phrx_backend
  ├── phrx_backend_worker
  ├── phrx_backend_print_worker
  ├── phrx_mysql      (sem ports públicos)
  └── phrx_redis      (sem ports públicos)
```

Fonte Compose: `infra/docker/phrx/docker-compose.prod.yml`
Nginx ref: `infra/nginx/skalway.conf`

## 1. Requisitos da VPS

| Item | Requisito |
|------|-----------|
| OS | Ubuntu LTS (22.04 ou 24.04) |
| Docker | Engine actual + plugin **Compose v2** (`docker compose`) |
| Nginx | Host (não o container de DEV) |
| UFW | Activo com regras mínimas |
| CPU | ≥ 2 vCPU |
| RAM | ≥ 4 GiB (mínimo absoluto 2 GiB — apertado) |
| Disco | ≥ 40 GiB SSD (≥ 20 GiB livres após SO) |
| Rede | IP público estável; portas 22/80/443 |

Pacotes típicos (instalação **manual** na VPS, fora deste script):

- `docker-ce` + `docker-compose-plugin`
- `nginx`
- `ufw`
- `curl`, `ca-certificates`

## 2. Estrutura de directórios (oficial)

```
/opt/skalway/
├── .env                      # secrets — chmod 600, NÃO no Git
├── docker-compose.prod.yml   # cópia do compose prod
├── backups/mysql/            # dumps (BACKUP_DIR)
├── logs/                     # logs operacionais do host (opcional)
└── apps/phrx/                # artefactos app (web build, etc.)

/var/www/phrx/                # Flutter Web publicado (root Nginx)

/etc/nginx/sites-available/skalway.conf
/etc/nginx/sites-enabled/skalway.conf   # symlink

/etc/ssl/cloudflare/
├── origin.crt                # 644
└── origin.key                # 600
```

### Relação com o monorepo

No Git a fonte da verdade continua em:

- `infra/docker/phrx/docker-compose.prod.yml`
- `infra/docker/phrx/.env.example`
- `infra/nginx/skalway.conf`
- `apps/phrx/`

Na VPS, o layout `/opt/skalway/` é o **runtime deploy** (ficheiros necessários apenas). Pode ser:

1. Clone completo do monorepo em `/opt/skalway` com symlink/cópia do compose para a raiz, **ou**
2. Pacote mínimo: compose + `.env` + imagem Docker + `build/web` → `/var/www/phrx`.

Ambos são válidos; o pre-flight assume o layout oficial acima.

## 3. Permissões e ownership

| Path | Owner sugerido | Modo |
|------|----------------|------|
| `/opt/skalway` | `deploy:deploy` (ou user de ops) | `750` |
| `/opt/skalway/.env` | mesmo user (ou root) | **`600`** |
| `/opt/skalway/backups` | mesmo user | `750` |
| `/var/www/phrx` | `www-data:www-data` (ou deploy + ACL) | `755` |
| `/etc/ssl/cloudflare/origin.crt` | `root:root` | **`644`** |
| `/etc/ssl/cloudflare/origin.key` | `root:root` | **`600`** |
| `/etc/nginx/sites-available/skalway.conf` | `root:root` | `644` |

Utilizador Docker: o user de deploy deve pertencer ao grupo `docker` **ou** usar `sudo` controlado — sem expor o socket Docker publicamente.

## 4. `.env`

- Copiar de `infra/docker/phrx/.env.example`
- Colocar em `/opt/skalway/.env`
- `chmod 600 /opt/skalway/.env`
- **Nunca** versionar no Git
- Gerar secrets reais **fora** do repositório

### Variáveis obrigatórias (produção)

| Variável | Função |
|----------|--------|
| `MYSQL_ROOT_PASSWORD` | Root MySQL (backup/health) |
| `MYSQL_USER` / `MYSQL_PASSWORD` | User app |
| `MYSQL_DATABASE` | Default `skalway_central` |
| `DATABASE_URL` | Prisma Central (`…@phrx-db:3306/skalway_central`) |
| `TENANT_DB_HOST` | `phrx-db` |
| `TENANT_DB_PORT` | `3306` |
| `TENANT_DB_USERNAME` / `TENANT_DB_PASSWORD` | Credenciais tenant |
| `JWT_SECRET_CENTRAL` | JWT Central |
| `JWT_SECRET_TENANT` | JWT Tenant |
| `ENCRYPTION_KEY` | 64 hex (32 bytes) — credenciais branch |

### Fortemente recomendadas

| Variável | Valor prod sugerido |
|----------|---------------------|
| `CORS_ALLOWED_ORIGINS` | `https://phrx.skalway.com` |
| `PUBLIC_TENANT_REGISTRATION` | `false` |
| `BACKEND_PORT` | `4001` |
| `TZ` | `Africa/Maputo` |
| `MPESA_WEBHOOK_SECRET` / `EMOLA_WEBHOOK_SECRET` | se webhooks activos |

Placeholders de DEV (`password`, `sua-secret-…`, `ENCRYPTION_KEY` a zeros) **não** são aceitáveis em produção — o pre-flight emite WARN.

## 5. Docker (produção)

- Network: `phrx_net` (bridge privada)
- Volumes: `phrx_mysql_data`, `phrx_redis_data`
- **MySQL:** sem `ports:` no host
- **Redis:** sem `ports:` no host
- **API:** apenas `127.0.0.1:4001` → container `:3300`
- Imagem: `skalway-phrx-backend:prod` (API + worker + print-worker)
- `NODE_ENV=production`
- Sem phpMyAdmin / bind-mount de código

Validar ficheiro (sem up):

```bash
cd /opt/skalway
docker compose -f docker-compose.prod.yml --env-file .env config
```

## 6. Nginx + Cloudflare Origin CA

1. Copiar `infra/nginx/skalway.conf` → `/etc/nginx/sites-available/skalway.conf`
2. Symlink em `sites-enabled`
3. Instalar Origin CA:
   - `/etc/ssl/cloudflare/origin.crt` (644)
   - `/etc/ssl/cloudflare/origin.key` (600)
4. `nginx -t` e reload (**manual**, não pelo pre-flight)
5. Cloudflare SSL/TLS: **Full (Strict)**

Rotas:

- `phrx.skalway.com` → `root /var/www/phrx` (SPA)
- `api.phrx.skalway.com` → `proxy_pass http://127.0.0.1:4001`
- HTTP :80 → redirect HTTPS

## 7. Firewall (UFW)

Regras alvo (aplicar **manualmente** na VPS):

| Porta | Acção |
|-------|--------|
| 22/tcp | ALLOW (restringir a IPs admin se possível) |
| 80/tcp | ALLOW |
| 443/tcp | ALLOW |
| 3306, 6379, 4001 | **não** abrir publicamente (4001 só loopback via Docker) |

Default: deny incoming / allow outgoing.

## 8. Backups

- Directório: `/opt/skalway/backups/mysql`
- Script: `infra/scripts/backup-mysql.sh`
- Descobre automaticamente `skalway_central` + `phrx_tenant_*_branch_*`
- Na VPS: `BACKUP_DIR=/opt/skalway/backups/mysql`

```bash
BACKUP_DIR=/opt/skalway/backups/mysql ./infra/scripts/backup-mysql.sh --dry-run
# futuro, após go-live: … --apply  (+ cron diário)
```

Ver: [docs/database/backups.md](../database/backups.md).

## 9. Pre-flight (script)

```bash
# A partir do repo (ou cópia dos scripts na VPS):
./infra/scripts/vps-preflight.sh --dry-run

# Na VPS (próxima etapa):
SKALWAY_ROOT=/opt/skalway ENV_FILE=/opt/skalway/.env \
  ./infra/scripts/vps-preflight.sh
```

Verifica apenas: Docker, Compose, Nginx, certificados, portas, UFW, directórios, DNS, disco, memória, variáveis obrigatórias.

**Não** instala, **não** altera firewall/Nginx/DNS, **não** inicia containers, **não** faz deploy.

Relacionado: `check-stack.sh` (estado do stack em execução) e `healthcheck.sh` (após containers up).

## 10. Checklist antes da próxima etapa

1. [ ] VPS Ubuntu com recursos mínimos
2. [ ] Docker + Compose instalados
3. [ ] Directórios `/opt/skalway/...` e `/var/www/phrx` criados
4. [ ] `.env` com secrets reais, `chmod 600`
5. [ ] `docker-compose.prod.yml` no sítio
6. [ ] Nginx + Origin CA (ficheiros presentes)
7. [ ] UFW 22/80/443
8. [ ] DNS Cloudflare `phrx` + `api.phrx` (Proxied) — processo manual
9. [ ] `./vps-preflight.sh` sem `[FAIL]`
10. [ ] Só então seguir [production.md](./production.md) para deploy

## Referências

- [production.md](./production.md)
- [docs/infrastructure/firewall.md](../infrastructure/firewall.md)
- [docs/infrastructure/ssl.md](../infrastructure/ssl.md)
- [infra/cloudflare/README.md](../../infra/cloudflare/README.md)

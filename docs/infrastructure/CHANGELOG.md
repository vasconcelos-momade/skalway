# Changelog de infraestrutura

Registo de decisões e mudanças de ops (não changelog de produto).

### 2026-08 — Preparação VPS (docs + pre-flight, sem deploy)

- Layout oficial `/opt/skalway`, `/var/www/phrx`, Nginx + Origin CA documentado em `docs/deployment/vps-preparation.md`.
- Script `infra/scripts/vps-preflight.sh` (report-only: Docker, Nginx, certs, portas, UFW, dirs, DNS, disco, mem, `.env`).
- `docs/deployment/production.md` actualizado com fases A (prep) / B (deploy futuro).

### 2026-08 — PROD BUILD (artefactos, sem deploy)

- Dockerfile prod: Bun `1.3`, deps Chromium (Puppeteer/print), `prisma:generate` na imagem, `NODE_ENV=production`.
- Compose prod validado: API `127.0.0.1:4001`, MySQL/Redis sem `ports:`, workers na mesma imagem.
- Flutter web release com `API_BASE_URL=https://api.phrx.skalway.com`.
- Documentados WARN de backup/restore/rollback (target-prefix, auth error, password CLI, `--confirm`).

## 2026-08 — Organização PhRx (repo)

### Decisões

- Ops canónicas em `infra/` (monorepo), não em `apps/phrx/infra/`.
- Domínios oficiais futuros: `phrx.skalway.com` + `api.phrx.skalway.com`.
- API container na porta **3300**; host prod **127.0.0.1:4001**.
- Naming multi-tenant: `skalway_central` + `phrx_tenant_{tenantId}_branch_{branchId}`.
- Stack real: Bun.serve (não Elysia); frontend Flutter (não Next.js).

### Docker

- Separação `docker-compose.dev.yml` / `docker-compose.prod.yml`.
- Prod: MySQL/Redis sem ports públicos; API só loopback; workers + print-worker; healthchecks.

### Nginx / Cloudflare

- Referência host: `infra/nginx/skalway.conf`.
- Planeamento Cloudflare: `infra/cloudflare/README.md` (Full Strict, Origin CA).

### Scripts

- Existentes: `bootstrap.sh`, `build.sh`, `deploy.sh` (dry-run).
- Adicionados: `healthcheck.sh`, `backup-mysql.sh`, `restore-mysql.sh`, `rollback.sh`, `check-stack.sh`.
- Dockerfile prod: Bun `1.3`, Chromium sistema + `PUPPETEER_SKIP_DOWNLOAD`, `prisma:generate`, imagem `skalway-phrx-backend:prod` (~1.88GB).

### Documentação

- Árvore `docs/{architecture,infrastructure,database,deployment,operations}/` criada.

### Naming

- Legado `api.skalway.com` / `pharm.*` documentado como não-padrão; builds devem migrar para `api.phrx.skalway.com`.

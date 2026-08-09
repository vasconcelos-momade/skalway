# Servidor (VPS) — planeamento

**NÃO provisionar nem alterar a VPS a partir deste doc automaticamente.**

Guia completo: [docs/deployment/vps-preparation.md](../deployment/vps-preparation.md)

## Papel do host Ubuntu

1. Nginx TLS (Cloudflare Origin CA)
2. Docker Engine + Compose
3. Static Flutter Web em `/var/www/phrx`
4. Loopback `127.0.0.1:4001` → container API

## Layout oficial (multi-app)

```
/opt/skalway-repo/                    # REPO_ROOT — monorepo
└── infra/docker/phrx/
    ├── docker-compose.prod.yml       # Compose PROD PhRx (oficial)
    └── .env                          # chmod 600

/opt/skalway/                         # SKALWAY_ROOT — runtime
├── backups/mysql/
└── logs/

/var/www/phrx/
/etc/nginx/sites-available/skalway.conf
/etc/nginx/sites-enabled/skalway.conf
/etc/ssl/cloudflare/{origin.crt,origin.key}
```

Não colocar `docker-compose.prod.yml` em `/opt/skalway/`.  
Outros produtos: `infra/docker/<app>/`.

## Recursos mínimos

- 2 vCPU · 4 GiB RAM · 40 GiB disco
- Portas públicas: 22, 80, 443 apenas

## Scripts

| Script | Função |
|--------|--------|
| `infra/scripts/vps-preflight.sh` | Pre-flight report-only (`REPO_ROOT` + `SKALWAY_ROOT`) |
| `infra/scripts/check-stack.sh` | Auditoria do stack |
| `infra/scripts/deploy.sh` | Compose prod (dry-run por omissão) |
| `infra/scripts/bootstrap.sh` | Pastas + `.env` local (dev/repo) |

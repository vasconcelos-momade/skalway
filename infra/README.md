# Infraestrutura Skalway

Operação, deploy e ambiente — **sem** código de negócio.

```
infra/
├── docker/phrx/     # compose DEV/PROD, .env.example, mysql init, nginx local
├── nginx/           # skalway.conf (referência host / TLS)
├── cloudflare/      # planeamento DNS/SSL (não aplicar agora)
├── scripts/         # bootstrap, build, deploy, health, backup, …
├── compose/         # índice (YAML canónico em docker/phrx/)
└── monitoring/      # placeholder
```

Documentação completa: [`docs/`](../docs/README.md).

## PhRx — DEV

```bash
cd infra/docker/phrx
cp -n .env.example .env
docker compose -f docker-compose.dev.yml up --build
```

Código: `apps/phrx/{backend,app}`
Serviços partilhados: `services/{identity,billing,...}`

## Scripts

| Script | Função |
|--------|--------|
| `scripts/bootstrap.sh` | pastas + `.env` local |
| `scripts/build.sh` | imagem backend + Flutter web |
| `scripts/deploy.sh` | compose prod (dry-run por omissão) |
| `scripts/vps-preflight.sh` | Pre-flight VPS (só verificação; próxima etapa) |
| `scripts/healthcheck.sh` | containers + API |
| `scripts/backup-mysql.sh` | dump Central + `phrx_tenant_*` |
| `scripts/restore-mysql.sh` | restore a partir de backup |
| `scripts/rollback.sh` | imagem anterior / restore |
| `scripts/check-stack.sh` | auditoria report-only |

Todos suportam `--dry-run` quando faz sentido. **Não executar contra VPS de produção nesta fase.**

## Produção (preparada)

- Compose: `docker/phrx/docker-compose.prod.yml`
- Nginx: `nginx/skalway.conf`
- Guia: [`docs/deployment/production.md`](../docs/deployment/production.md)

# Operações — backups

Ver detalhe técnico: [docs/database/backups.md](../database/backups.md).

## Rotina futura (prod)

1. Cron diário: `backup-mysql.sh --apply`
2. Copiar tarball offsite (object storage / outro host)
3. Testar restore trimestralmente numa VM isolada
4. Manter `prod-prev` da imagem Docker após cada release

## O que incluir

- Todas as bases descobertas: Central + `phrx_tenant_*_branch_*`
- Manifest + checksums
- Não esquecer volumes Redis só se houver estado crítico (AOF já persiste; MySQL é prioritário)

## O que nunca fazer

- `docker compose down -v` em prod
- Commit de dumps com dados reais no Git

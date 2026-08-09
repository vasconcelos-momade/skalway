# Release (futuro)

## Artefactos

1. Imagem `skalway-phrx-backend:prod` (`./infra/scripts/build.sh --backend-only`)
2. Flutter Web (`./infra/scripts/build.sh --web-only` com `API_BASE_URL=https://api.phrx.skalway.com`)
3. Notas de migrations Central + Tenant

## Sequência sugerida

1. `backup-mysql.sh --apply`
2. Tag imagem anterior como `skalway-phrx-backend:prod-prev` (para rollback)
3. Build / pull nova imagem
4. `deploy.sh --apply` (quando autorizado)
5. Migrations
6. Rsync/copy `build/web` → `/var/www/phrx`
7. `healthcheck.sh`
8. Smoke login + POS numa filial piloto

## Versionamento

Preferir tag Git + tag Docker alinhadas (`prod-YYYYMMDD` ou semver interno).

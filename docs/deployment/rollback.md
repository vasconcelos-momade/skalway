# Rollback

Script: `infra/scripts/rollback.sh` (dry-run por omissão).

## Cenários

| Problema | Acção |
|----------|--------|
| Bug na API | Retag `prod-prev` → `prod`, `compose up -d` backend/workers |
| Dados corrompidos | `restore-mysql.sh --from <backup>` |
| Frontend mau | Restaurar cópia anterior de `/var/www/phrx` |

## Procedimento

```bash
./infra/scripts/rollback.sh --dry-run
./infra/scripts/rollback.sh --image skalway-phrx-backend:prod-prev --apply
# com BD:
./infra/scripts/rollback.sh --from-backup /path/to/backup --apply
```

Depois: `healthcheck.sh` e validação manual.

**NÃO** usar `docker compose down -v` em produção (apaga volumes).

### WARN / melhorias futuras

- Adicionar `--confirm` (ou dupla confirmação) antes de qualquer `--apply` que altere compose/imagem/BD.
- Não executar `--apply` em ensaios locais sem imagem `prod-prev` validada.
- Restauração MySQL via rollback herda limitações de `restore-mysql.sh` (ver [docs/database/backups.md](../database/backups.md)).

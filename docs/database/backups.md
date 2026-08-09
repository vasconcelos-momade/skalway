# Backups MySQL

## Script

`infra/scripts/backup-mysql.sh`

- Descobre automaticamente `skalway_central` e `phrx_tenant_*_branch_*`
- Sem lista fixa de bases
- Dry-run por omissão; `--apply` para executar localmente
- Gzip + SHA-256; retenção default **14 dias** (`RETENTION_DAYS`)

```bash
./infra/scripts/backup-mysql.sh              # plano
MYSQL_ROOT_PASSWORD=… ./infra/scripts/backup-mysql.sh --apply
```

Destino default: `infra/docker/phrx/backups/mysql/<timestamp>/`

## Restore

`infra/scripts/restore-mysql.sh --from <dir> [--db nome] [--apply]`

Verificar checksum `.sha256` antes do import.

**ATENÇÃO:** `--apply` restaura nos nomes originais das bases (`CREATE DATABASE` / `USE` do dump) e sobrescreve dados.

### WARN / melhorias futuras (ensaio DEV 2026-08)

| Item | Estado | Acção futura |
|------|--------|--------------|
| Restore para DB de teste | em falta | Adicionar `--target-prefix` / `--target-db` (restore não destrutivo) |
| Erro de autenticação MySQL | genérico | Falhar cedo com mensagem clara se password inválida |
| Password na CLI | aviso mysqldump | Evitar `-p` na linha de comando (ficheiro `.my.cnf` efémero) |
| Rollback sem confirmação | dry-run por omissão | Adicionar `--confirm` / guardrails antes de `--apply` |

Ensaio DEV validou backup + integridade via restore manual para `phrx_restore_test_*` (sem sobrescrever live).

## Retenção

| Ambiente | Sugestão |
|----------|----------|
| Dev | 7–14 dias local |
| Prod (futuro) | diário 14d + semanal 8w + mensal offsite |

## Produção

Não correr backup contra a VPS nesta fase de organização.

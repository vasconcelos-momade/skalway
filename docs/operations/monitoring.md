# Monitorização

Estado actual: placeholder em `infra/monitoring/README.md`.

## Mínimo futuro

| Sinal | Como |
|-------|------|
| API up | `GET /api/v1/health` (Nginx + Cloudflare) |
| Containers | `docker ps` / restart policies |
| Disco | alertas host (volumes MySQL/Redis) |
| Logs | `json-file` rotativos no compose prod |

## Scripts

- `infra/scripts/healthcheck.sh` — checks locais
- `infra/scripts/check-stack.sh` — auditoria report-only

## Próximos passos (não nesta fase)

- Uptime externo (Healthchecks.io / Cloudflare Health Checks)
- Métricas (Prometheus/cAdvisor) se necessário
- Alertas de falha de backup

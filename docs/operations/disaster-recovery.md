# Disaster recovery

## Objectivo RTO/RPO (a calibrar antes do go-live)

| | Alvo inicial sugerido |
|--|------------------------|
| RPO | ≤ 24h (backup diário) |
| RTO | horas (rebuild host + restore + DNS) |

## Cenários

### Perda de container / imagem má

1. `rollback.sh` para imagem `prod-prev`
2. Healthcheck
3. Sem restore BD se dados intactos

### Perda / corrupção MySQL

1. Parar writers (backend/workers)
2. `restore-mysql.sh --from <último bom>`
3. Subir stack + validar filiais piloto
4. Investigar causa

### Perda total da VPS

1. Nova VPS + Docker + Nginx + Origin CA
2. DNS Cloudflare para novo IP (ou mesmo IP se reatribuído)
3. Restore volumes/dumps
4. Publicar Flutter Web
5. `check-stack.sh --full`

### Cloudflare / SSL

- 525/526: repor Origin CA e Full Strict
- Manter cópia segura de `origin.key` (fora do Git, backup cifrado)

## Exercício

Documentar e ensaiar restore **antes** do primeiro deploy real.

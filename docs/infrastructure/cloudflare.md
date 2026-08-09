# Cloudflare

Documento canónico curto: [infra/cloudflare/README.md](../../infra/cloudflare/README.md).

## Resumo

- DNS A `phrx` e `api-phrx` → IP da VPS, **Proxied**
- Hostname API: `api-phrx.skalway.com` (não criar `api.phrx.skalway.com`)
- SSL/TLS: **Full (Strict)**
- Origin CA no Nginx do host
- API: bypass cache; frontend: cache de assets OK
- WAF / rate limit em login e webhooks (recomendado)

## Erros 52x

| Código | Causa típica |
|--------|----------------|
| 521 | Origin down (Nginx/Docker/API/firewall) |
| 522 | Timeout na origin |
| 525 | Handshake SSL falhou (Origin CA / modo SSL) |
| 526 | Certificado origin inválido |

**NÃO modificar Cloudflare nesta fase.**

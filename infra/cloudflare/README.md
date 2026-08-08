# Cloudflare — configuração futura (PhRx)

**NÃO alterar Cloudflare nesta fase.** Documento de planeamento apenas.

## DNS (proxied)

| Tipo | Nome | Conteúdo | Proxy |
|------|------|----------|-------|
| A | `phrx` | `162.35.184.167` | Proxied (laranja) |
| A | `api.phrx` | `162.35.184.167` | Proxied (laranja) |

Resultado:

- `https://phrx.skalway.com` → frontend
- `https://api.phrx.skalway.com` → API

> Substituir o IP pelo da VPS real no momento do deploy.

## SSL/TLS

- Modo: **Full (Strict)**
- Origin Certificate (Cloudflare Origin CA) instalado no Nginx do host:
  - `/etc/ssl/cloudflare/origin.crt` (644)
  - `/etc/ssl/cloudflare/origin.key` (600)

## Proxy / cache

- API (`api.phrx`): **bypass cache** (dinamismo + auth)
- Frontend (`phrx`): cache de assets estáticos OK; HTML com revalidação curta

## WAF / segurança (recomendado)

- WAF gerido Cloudflare
- Rate limiting em `/api/v1/central/auth/login` e webhooks
- Bot Fight Mode / Super Bot Fight conforme necessidade

## Erros comuns

| Código | Significado | Acção típica |
|--------|-------------|--------------|
| 521 | Origin down | Nginx/Docker/API parados; firewall a bloquear 443 |
| 522 | Timeout | Origin não responde a tempo; overload / rede |
| 525 | SSL handshake failed | Certificado Origin em falta/errado; Full Strict sem Origin CA |
| 526 | Invalid SSL certificate | Cert inválido / hostname mismatch no Origin |

## Checklist (futuro)

1. Criar registos A proxied
2. Gerar Origin CA e instalar no host
3. SSL/TLS → Full (Strict)
4. Validar `curl -I https://api.phrx.skalway.com/api/v1/health`
5. Validar frontend carrega e chama a API (CORS)

Ver: `docs/infrastructure/cloudflare.md`, `docs/infrastructure/ssl.md`.

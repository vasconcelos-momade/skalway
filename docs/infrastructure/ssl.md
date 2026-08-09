# SSL / TLS

## Produção planeada

```
Cliente → Cloudflare (edge TLS) → Origin (Nginx TLS Full Strict) → HTTP local → Docker API
```

## Origin Certificate (Cloudflare)

1. Cloudflare Dashboard → SSL/TLS → Origin Server → Create Certificate
2. Instalar no host:
   - cert → `/etc/ssl/cloudflare/origin.crt` (`644`)
   - key → `/etc/ssl/cloudflare/origin.key` (`600`)
3. Referenciar em `infra/nginx/skalway.conf`
4. Modo Cloudflare: **Full (Strict)**

## DEV

Sem TLS obrigatório: `http://localhost:4001` / `http://localhost:8280`.

## Não fazer nesta fase

Não gerar/instalar certificados na VPS, não alterar Cloudflare.

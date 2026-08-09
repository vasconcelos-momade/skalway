# Nginx

## Dois papéis

1. **DEV (container)** — `infra/docker/phrx/nginx/default.conf`
   Proxy local + static uploads; porta host `8280`.

2. **PROD (host Ubuntu)** — referência em `infra/nginx/skalway.conf`
   **Não instalar automaticamente.** Copiar manualmente no deploy futuro.

## Produção (referência)

| `server_name` | Destino |
|---------------|---------|
| `phrx.skalway.com` | `root /var/www/phrx` (Flutter Web SPA) |
| `api-phrx.skalway.com` | `proxy_pass` → `127.0.0.1:4001` |

TLS (Cloudflare Origin CA):

- `/etc/ssl/cloudflare/origin.crt` (644)
- `/etc/ssl/cloudflare/origin.key` (600)

HTTP :80 → redirect 301 para HTTPS.

## Activação futura (manual)

```bash
sudo cp infra/nginx/skalway.conf /etc/nginx/sites-available/skalway-phrx.conf
sudo ln -sf /etc/nginx/sites-available/skalway-phrx.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

Não executar estes passos nesta fase de organização.

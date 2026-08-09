# Domínios

## Padrão oficial (PhRx)

| Uso | Domínio |
|-----|---------|
| Flutter Web | `phrx.skalway.com` |
| API | `api-phrx.skalway.com` |

## DNS futuro (Cloudflare, proxied)

| Tipo | Nome | Conteúdo | Proxy |
|------|------|----------|-------|
| A | `phrx` | IP da VPS (ex. `162.35.184.167`) | Proxied |
| A | `api-phrx` | mesmo IP | Proxied |

Ver: [infra/cloudflare/README.md](../../infra/cloudflare/README.md).

## Legado (não usar)

- `pharm.skalway.com` / `api.pharm.skalway.com`
- `api.skalway.com`
- `api.phrx.skalway.com` (substituído por `api-phrx.skalway.com`)

O padrão oficial de builds e documentação é sempre `api-phrx.skalway.com`.

## Flutter Web

Build:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api-phrx.skalway.com \
  --dart-define=API_CLOUD_URL=https://api-phrx.skalway.com
```

Publicação futura: conteúdo de `apps/phrx/app/build/web` → `/var/www/phrx/`.

Variáveis reais no projeto: `API_BASE_URL`, `API_CLOUD_URL` (ver `apps/phrx/app/.env.example`).

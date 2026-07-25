# Infraestrutura Skalway

Tudo o que é **operação, deploy e ambiente** — não código de negócio.

```
infra/
├── docker/          # compose, imagens, init DB por produto
│   └── phrx/
├── nginx/           # reverse-proxy / rotas por domínio
└── monitoring/      # métricas, logs, alertas
```

## PhRx (dev)

```bash
cd infra/docker/phrx
docker compose -f docker-compose.dev.yml up --build
```

Código do produto: `apps/phrx/{backend,app}`  
Serviços partilhados: `services/{identity,billing,...}`

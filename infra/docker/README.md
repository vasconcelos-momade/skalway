# Infra Docker

Compose e artefactos de ambiente por produto.

```
docker/
└── phrx/
    ├── docker-compose.dev.yml
    ├── docker-compose.prod.yml
    ├── docker-compose.yml      # LEGACY / DEPRECATED — usar .dev.yml ou .prod.yml
    ├── .env.example
    ├── mysql/
    └── nginx/
```

O código de negócio **não** vive aqui — apenas em `apps/` e `services/`.
Docs: [`docs/infrastructure/docker.md`](../../docs/infrastructure/docker.md).

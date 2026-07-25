# Infra Docker

Compose e artefactos de ambiente por produto.

```
docker/
└── phrx/
    ├── docker-compose.yml
    ├── docker-compose.dev.yml
    ├── .env.example
    ├── mysql/
    └── nginx/
```

O código de negócio **não** vive aqui — apenas em `apps/` e `services/`.

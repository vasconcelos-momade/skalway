# Compose PhRx — índice

Os ficheiros canónicos de Compose vivem em:

```
infra/docker/phrx/
├── docker-compose.dev.yml    # OFICIAL — desenvolvimento local
├── docker-compose.prod.yml   # OFICIAL — produção preparada
└── docker-compose.yml        # LEGACY / DEPRECATED — não usar
```

**Compose oficiais:** apenas `.dev.yml` e `.prod.yml`.
`docker-compose.yml` está marcado como LEGACY/DEPRECATED (compatibilidade apenas).

Esta pasta (`infra/compose/`) existe para alinhar com a estrutura documental
pedida (`compose/dev` + `compose/prod`) **sem duplicar** YAML.

## DEV

```bash
cd infra/docker/phrx
cp -n .env.example .env   # se ainda não existir
docker compose -f docker-compose.dev.yml up --build
```

## PRODUÇÃO (futuro — NÃO executar agora)

```bash
cd infra/docker/phrx
# .env com secrets reais (chmod 600)
docker compose -f docker-compose.prod.yml --env-file .env config   # validar
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

Ver também: `docs/deployment/production.md`, `docs/infrastructure/docker.md`.

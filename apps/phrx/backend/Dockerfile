# PhRx backend — imagem de PRODUÇÃO
# Build context: skalway/ (monorepo root)
#   docker build -f apps/phrx/backend/Dockerfile -t skalway-phrx-backend:prod .
#
# Usada por: phrx-backend, phrx-backend-worker, phrx-backend-print-worker, phrx-migrate
# (sem bind-mount de código)

FROM oven/bun:1.3

WORKDIR /usr/src/app

# Chromium runtime deps (Puppeteer / PDF / print-worker)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libglib2.0-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libx11-6 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libxshmfence1 \
    libxss1 \
    && rm -rf /var/lib/apt/lists/*

# @skalway/* — file:../../../services/* resolve para /services/*
COPY services/identity /services/identity
COPY services/billing /services/billing
COPY apps/phrx/backend/package.json apps/phrx/backend/bun.lock* ./

# Evitar download do Chromium do Puppeteer durante o build (lento/instável).
# Usar Chromium do sistema (abaixo).
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

RUN bun install --frozen-lockfile || bun install

COPY apps/phrx/backend/ .

# Clients Prisma + CLI (devDependency) — bun install corre ANTES de NODE_ENV=production
# Necessário para phrx-migrate: bunx prisma migrate deploy
ENV PRISMA_CLIENT_ENGINE_TYPE=binary
RUN bun run prisma:generate \
  && test -f src/infrastructure/prisma/central/schema.prisma \
  && test -d src/infrastructure/prisma/central/migrations \
  && bunx prisma --version

# Chromium para PDF / print-worker (além das libs já instaladas)
RUN apt-get update && apt-get install -y --no-install-recommends chromium \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/chromium /usr/bin/chromium-browser || true

EXPOSE 3300

ENV NODE_ENV=production

CMD ["bun", "run", "start"]

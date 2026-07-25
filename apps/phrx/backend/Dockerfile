FROM oven/bun:1

# Build context: skalway/ (monorepo root)
WORKDIR /usr/src/app

COPY services/identity /services/identity
COPY services/billing /services/billing
COPY apps/phrx/backend/package.json apps/phrx/backend/bun.lock* ./

RUN bun install --frozen-lockfile || bun install

COPY apps/phrx/backend/ .

EXPOSE 3300

CMD ["bun", "run", "start"]

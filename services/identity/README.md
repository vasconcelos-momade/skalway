# Identity Service

Pacote partilhado `@skalway/identity`.

## Responsabilidades (extractadas)

- JWT central / tenant (`JwtService`)
- Lockout de login e hash de sessão (`login-security`)

## Ainda no PhRx (próxima extracção)

- Rotas HTTP (`apps/phrx/backend/src/routes/v1/auth.routes.ts`)
- `LoginUseCase` / `ForgotPasswordUseCase` (dependem de Prisma + tenant context)
- Middlewares `shared/http/*auth*`

## Uso no PhRx

```ts
import { JwtService, isAccountLocked } from "@skalway/identity";
```

Dependência: `"@skalway/identity": "file:../../../../services/identity"`

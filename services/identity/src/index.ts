/**
 * @skalway/identity
 *
 * Core partilhado: JWT + lockout/sessão.
 * Rotas HTTP e resolução de tenant/RBAC ficam no produto (PhRx).
 *
 * Fonte original: apps/phrx/backend infrastructure/auth + security
 */
export { JwtService } from "./jwt.service";
export type { CentralPayload, TenantPayload } from "./jwt.service";

export {
  hashSessionToken,
  getLockDurationMs,
  isAccountLocked,
  shouldLockAccount,
  nextLockUntil,
  resetAfterSuccess,
  incrementAfterFailure,
} from "./login-security.service";

export const service = {
  name: "identity",
  version: "0.1.0",
  responsibilities: [
    "jwt",
    "login-lockout",
    "session-token-hash",
  ] as const,
} as const;

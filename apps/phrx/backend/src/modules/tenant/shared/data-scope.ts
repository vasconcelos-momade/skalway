import { getPrisma } from "../../../infrastructure/prisma/tenant-prisma.factory";
import { ForbiddenApiError } from "../../../shared/http/api-error";
import {
  TENANT_PERMISSION_ROLES,
  type TenantPermissionRole,
} from "./permission.constants";

/** Perfis que veem apenas a própria actividade operacional. */
export const OPERATIONAL_DATA_SCOPE_ROLES = new Set<TenantPermissionRole>([
  "CAIXA",
  "FARMACEUTICO",
]);

/** Perfis que veem todos os dados da filial (com filtros opcionais). */
export const MANAGEMENT_DATA_SCOPE_ROLES = new Set<TenantPermissionRole>([
  "ADMIN",
  "GERENTE",
  "DIRETOR_TECNICO",
]);

export type DataScopeMode = "OWN" | "ALL";

export type DataScope = {
  mode: DataScopeMode;
  /** Sempre o utilizador autenticado (tenant `users.id`). */
  actorUserId: string;
  role: TenantPermissionRole | string | null;
  /**
   * Quando `mode === "OWN"`, filtro obrigatório a aplicar nas consultas.
   * Quando `mode === "ALL"`, pode ser um filtro opcional pedido pelo cliente.
   */
  filterUserId: string | null;
};

export function isTenantPermissionRole(value: string | null | undefined): value is TenantPermissionRole {
  return TENANT_PERMISSION_ROLES.includes(value as TenantPermissionRole);
}

export function isOperationalRole(role: string | null | undefined): boolean {
  return isTenantPermissionRole(role) && OPERATIONAL_DATA_SCOPE_ROLES.has(role);
}

export function isManagementRole(role: string | null | undefined): boolean {
  return isTenantPermissionRole(role) && MANAGEMENT_DATA_SCOPE_ROLES.has(role);
}

/**
 * Resolve o escopo de dados a partir do role e do actor.
 * Operacionais: força a própria actividade (ignora `requestedUserId` do cliente).
 * Gestão: vê tudo; `requestedUserId` actua apenas como filtro opcional.
 */
export function resolveDataScope(input: {
  actorUserId: string;
  role: string | null | undefined;
  requestedUserId?: string | null;
}): DataScope {
  const actorUserId = String(input.actorUserId);
  const role = input.role ?? null;
  const requested = input.requestedUserId?.trim() || null;

  if (isOperationalRole(role)) {
    return {
      mode: "OWN",
      actorUserId,
      role,
      filterUserId: actorUserId,
    };
  }

  return {
    mode: "ALL",
    actorUserId,
    role,
    filterUserId: requested,
  };
}

/** Carrega o role do utilizador na base tenant e resolve o escopo. */
export async function resolveDataScopeForUser(input: {
  actorUserId: string;
  requestedUserId?: string | null;
}): Promise<DataScope> {
  const prisma = getPrisma();
  const user = await prisma.user.findUnique({
    where: { id: BigInt(input.actorUserId) },
    select: { role: true, active: true, deletedAt: true },
  });

  if (!user || user.deletedAt || !user.active) {
    throw new ForbiddenApiError("Utilizador inactivo ou sem acesso ao tenant");
  }

  return resolveDataScope({
    actorUserId: input.actorUserId,
    role: String(user.role),
    requestedUserId: input.requestedUserId,
  });
}

/** Fragmento Prisma `{ userId: bigint }` quando há filtro de utilizador. */
export function userScopeWhere(
  scope: DataScope,
  field: string = "userId",
): Record<string, bigint> {
  if (!scope.filterUserId) return {};
  return { [field]: BigInt(scope.filterUserId) };
}

/**
 * Garante que um registo com `ownerUserId` é visível no escopo actual.
 * Gestão passa sempre; operacionais só acedem aos próprios registos.
 */
export function assertRecordVisibleToScope(
  scope: DataScope,
  ownerUserId: string | bigint | null | undefined,
  message = "Acesso negado a dados de outro utilizador",
): void {
  if (scope.mode !== "OWN") return;
  if (ownerUserId == null) {
    throw new ForbiddenApiError(message);
  }
  if (String(ownerUserId) !== scope.actorUserId) {
    throw new ForbiddenApiError(message);
  }
}

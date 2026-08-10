import type { PrismaClient as PrismaTenantClient } from "../../../infrastructure/prisma/tenant/generated/tenant";
import {
  resolveTenantUserId,
  TenantUserNotFoundError,
  type ResolveTenantUserInput,
} from "./resolve-tenant-user";

/**
 * Garante que o Super Admin existe na BD tenant (role ADMIN).
 * Necessário para FKs/auditoria ao operar rotas /tenant/*.
 */
export async function ensureSuperAdminTenantUser(
  prisma: Pick<PrismaTenantClient, "user">,
  input: ResolveTenantUserInput & { name?: string | null },
): Promise<bigint> {
  try {
    return await resolveTenantUserId(prisma, input);
  } catch (error) {
    if (!(error instanceof TenantUserNotFoundError)) {
      throw error;
    }
  }

  const email = input.email?.trim().toLowerCase() || null;
  const name = input.name?.trim() || "Super Admin";
  const centralId = BigInt(input.centralUserId);

  const created = await prisma.user.create({
    data: {
      name,
      email,
      role: "ADMIN",
      centralUserId: centralId,
      active: true,
    },
    select: { id: true },
  });

  return created.id;
}

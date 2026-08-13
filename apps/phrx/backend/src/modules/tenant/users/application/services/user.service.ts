import bcrypt from "bcryptjs";
import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { UserRepository } from "../../infrastructure/repositories/user.repository";
import { RolePermissionRepository } from "../../infrastructure/repositories/role-permission.repository";
import type { CreateUserDTO, UpdateUserDTO } from "../dto/user.dto";

/**
 * Cria credenciais de login na central + vínculo user_tenants,
 * e devolve o centralUserId para o perfil tenant.
 */
async function provisionCentralLoginAccess(params: {
  name: string;
  email: string;
  password: string;
  role: CreateUserDTO["role"];
  active: boolean;
  tenantId: string;
}): Promise<string> {
  const prisma = prismaCentralUnscoped as any;
  const email = params.email.trim().toLowerCase();
  const hashedPassword = await bcrypt.hash(params.password, 10);
  const tenantId = BigInt(params.tenantId);

  // Email só está ocupado se existir utilizador com deletedAt IS NULL.
  // Soft-deleted mantêm-se intactos; cria-se um novo registo quando necessário.
  let centralUser = await prisma.user.findFirst({
    where: { email, deletedAt: null },
  });

  if (centralUser) {
    centralUser = await prisma.user.update({
      where: { id: centralUser.id },
      data: {
        name: params.name,
        password: hashedPassword,
        active: params.active,
      },
    });
  } else {
    centralUser = await prisma.user.create({
      data: {
        name: params.name,
        email,
        password: hashedPassword,
        role: "usuario",
        active: params.active,
      },
    });
  }

  const existingLink = await prisma.userTenant.findFirst({
    where: {
      userId: centralUser.id,
      tenantId,
      deletedAt: null,
    },
  });

  if (existingLink) {
    await prisma.userTenant.update({
      where: { id: existingLink.id },
      data: {
        role: params.role,
        active: params.active,
      },
    });
  } else {
    await prisma.userTenant.create({
      data: {
        userId: centralUser.id,
        tenantId,
        role: params.role,
        active: params.active,
      },
    });
  }

  return centralUser.id.toString();
}

export class UserService {
  private repo = new UserRepository();
  private permissions = new RolePermissionRepository();

  async create(data: CreateUserDTO, actorId: string, tenantId: string) {
    const active = data.active ?? true;
    const centralUserId = await provisionCentralLoginAccess({
      name: data.name,
      email: data.email,
      password: data.password,
      role: data.role,
      active,
      tenantId,
    });

    return this.repo.create(
      {
        name: data.name,
        email: data.email,
        role: data.role,
        active,
        centralUserId,
      },
      BigInt(actorId),
    );
  }

  update(id: string, data: UpdateUserDTO, actorId: string) {
    return this.repo.update(BigInt(id), data, BigInt(actorId));
  }

  delete(id: string, actorId: string) {
    return this.repo.softDelete(BigInt(id), BigInt(actorId));
  }

  search(filters: Parameters<UserRepository["search"]>[0]) {
    return this.repo.search(filters);
  }

  get(id: string) {
    return this.repo.getById(BigInt(id));
  }

  getDashboard() {
    return this.repo.getDashboard();
  }

  listAudit(userId: string, page?: number, pageSize?: number) {
    return this.repo.listAuditLogs(BigInt(userId), page, pageSize);
  }

  listEvents(userId: string, page?: number, pageSize?: number) {
    return this.repo.listBusinessEvents(BigInt(userId), page, pageSize);
  }

  listRoles() {
    return this.permissions.listRoles();
  }

  getRoleDetail(role: string) {
    return this.permissions.getRoleDetail(role);
  }

  getPermissionMatrix(role?: string) {
    return this.permissions.getPermissionMatrix(role);
  }

  updateRolePermissions(
    role: string,
    grants: Array<{ module: string; action: string; enabled: boolean }>,
    actorId: string,
  ) {
    return this.permissions.updateRolePermissions(role, grants, BigInt(actorId));
  }

  updateUserPermissions(
    userId: string,
    permissions: Array<{
      module: string;
      action: string;
      allowed?: boolean;
      clear?: boolean;
    }>,
    actorId: string,
  ) {
    return this.permissions.updateUserPermissions(
      BigInt(userId),
      permissions,
      BigInt(actorId),
    );
  }

  getUserEffectivePermissions(userId: string) {
    return this.permissions.getUserEffectivePermissions(BigInt(userId));
  }

  getPermissionsDashboard() {
    return this.permissions.getDashboard();
  }
}

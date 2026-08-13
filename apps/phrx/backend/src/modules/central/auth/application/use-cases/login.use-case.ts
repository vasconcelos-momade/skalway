import bcrypt from 'bcryptjs';
import { prismaCentralUnscoped } from '../../../../../infrastructure/prisma/prisma-central.service';
import { JwtService } from '../../../../../infrastructure/auth/jwt.service';
import {
  hashSessionToken,
  incrementAfterFailure,
  isAccountLocked,
  resetAfterSuccess,
} from '../../../../../infrastructure/security/login-security.service';
import { ApiError } from '../../../../../shared/http/api-error';
import { resolveLoginTenantContext } from '../login-tenant-context';

const INVALID_CREDENTIALS_MESSAGE = 'Email ou palavra-passe incorretos.';

interface UserTenantWithTenant {
  tenant: {
    id: bigint;
    tenantKey: string;
    tenantName: string;
    branches: {
      id: bigint;
      code: string;
      name: string;
    }[];
  };
}

export interface LoginMeta {
  ip?: string;
  userAgent?: string;
}

const SESSION_TTL_MS = Number(process.env.SESSION_TTL_MS ?? 24 * 60 * 60 * 1000);

export class LoginUseCase {
  async execute(email: string, password: string, meta?: LoginMeta) {
    const prisma = prismaCentralUnscoped as any;
    const normalizedEmail = email.trim().toLowerCase();

    const user = await prisma.user.findFirst({
      where: { email: normalizedEmail, deletedAt: null },
      include: {
        userTenants: {
          where: {
            active: true,
            deletedAt: null,
            tenant: { deletedAt: null },
          },
          include: {
            tenant: {
              include: {
                branches: {
                  where: { active: true, deletedAt: null },
                  select: {
                    id: true,
                    code: true,
                    name: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!user) {
      await this.recordAttempt(normalizedEmail, false, null, meta);
      throw new ApiError(
        INVALID_CREDENTIALS_MESSAGE,
        401,
        'AUTH_INVALID_CREDENTIALS',
      );
    }

    if (user.deletedAt != null || user.active === false) {
      await this.recordAttempt(normalizedEmail, false, user.id, meta);
      throw new ApiError(
        'A sua conta está inativa.',
        403,
        'AUTH_ACCOUNT_INACTIVE',
      );
    }

    if (isAccountLocked(user.lockedUntil)) {
      throw new ApiError(
        'A sua conta encontra-se bloqueada.',
        403,
        'AUTH_ACCOUNT_LOCKED',
      );
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    await this.recordAttempt(normalizedEmail, isPasswordValid, user.id, meta);

    if (!isPasswordValid) {
      const { failedLoginCount, lockedUntil } = incrementAfterFailure(
        user.failedLoginCount ?? 0,
      );
      await prisma.user.update({
        where: { id: user.id },
        data: { failedLoginCount, lockedUntil },
      });
      throw new ApiError(
        INVALID_CREDENTIALS_MESSAGE,
        401,
        'AUTH_INVALID_CREDENTIALS',
      );
    }

    const expiresAt = new Date(Date.now() + SESSION_TTL_MS);

    const token = JwtService.signCentral({
      sub: user.id.toString(),
      email: user.email,
      tenants: ((user as any).userTenants as UserTenantWithTenant[]).map((ut) => ({
        id: ut.tenant.id.toString(),
        branches: ut.tenant.branches.map((branch) => ({
          id: branch.id.toString(),
          code: branch.code,
          name: branch.name,
        })),
      })),
    });

    await prisma.user.update({
      where: { id: user.id },
      data: {
        lastLoginAt: new Date(),
        ...resetAfterSuccess(),
      },
    });

    await prisma.userSession.create({
      data: {
        userId: user.id,
        tokenHash: hashSessionToken(token),
        expiresAt,
        lastActivityAt: new Date(),
        ip: meta?.ip,
        userAgent: meta?.userAgent,
      },
    });

    const mappedTenants = ((user as any).userTenants as UserTenantWithTenant[]).map((ut) => ({
      id: ut.tenant.id.toString(),
      tenantKey: ut.tenant.tenantKey,
      tenantName: ut.tenant.tenantName,
      branches: ut.tenant.branches.map((branch) => ({
        id: branch.id.toString(),
        code: branch.code,
        name: branch.name,
      })),
    }));

    const context = await resolveLoginTenantContext({
      role: user.role,
      userId: user.id.toString(),
      email: user.email,
      tenants: mappedTenants,
    });

    return {
      token,
      user: {
        id: user.id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
      },
      role: context.role,
      tenantId: context.tenantId,
      branchId: context.branchId,
      permissions: context.permissions,
      tenants: mappedTenants,
      redirectTo: context.redirectTo,
    };
  }

  private async recordAttempt(
    email: string,
    success: boolean,
    userId: bigint | null,
    meta?: LoginMeta,
  ): Promise<void> {
    const prisma = prismaCentralUnscoped as any;
    await prisma.loginAttempt.create({
      data: {
        email,
        success,
        userId,
        ip: meta?.ip,
        userAgent: meta?.userAgent,
      },
    });
  }
}

import bcrypt from "bcryptjs";
import { z } from "zod";
import { Role } from "../../../../infrastructure/prisma/central/generated/central";
import { prismaCentral } from "../../../../infrastructure/prisma/prisma-central.service";
import { JobQueueService } from "../../../../infrastructure/queue/job-queue.service";
import {
  CreateTenantUseCase,
  isValidNuit,
  normalizeTenantSlug,
} from "../../tenants/application/use-cases/create-tenant.use-case";
import { DeleteTenantUseCase } from "../../tenants/application/use-cases/delete-tenant.use-case";
import type { CentralAuthContext } from "../../../../shared/http/central-auth";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { success } from "../../../../shared/http/api-response";
import { parseJsonBody, parseSearchParams } from "../../../../shared/http/request-validation";
import { writeCentralAuditLog } from "../../infrastructure/central-audit.helper";
import { controllerErrorResponse } from "../../../../shared/http/controller-error";

const ownerUserSchema = z.object({
  name: z.string().trim().min(1),
  email: z.string().trim().pipe(z.email()),
  password: z.string().min(6),
  role: z.enum(["superadmin", "admin", "usuario"]).optional(),
});

const branchInputSchema = z.object({
  name: z.string().trim().min(1),
});

const registerTenantSchema = z
  .object({
    tenantName: z.string().trim().min(1, "Nome do tenant é obrigatório"),
    userId: z.string().trim().min(1).optional(),
    ownerUser: ownerUserSchema.optional(),
    email: z.string().trim().pipe(z.email()).optional().nullable(),
    endereco: z.string().trim().min(1).optional().nullable(),
    nuit: z.string().trim().min(1).optional().nullable(),
    telefone: z.string().trim().min(1).optional().nullable(),
    planSlug: z.string().trim().min(1).optional().nullable(),
    status: z.enum(["trial", "ativo"]).optional().nullable(),
    billingPeriodMonths: z.coerce
      .number()
      .int()
      .refine((v) => [1, 3, 6, 12].includes(v), {
        message: "Período de faturação inválido (1, 3, 6 ou 12).",
      })
      .optional()
      .nullable(),
    branchName: z.string().trim().min(1).optional().nullable(),
    branches: z.array(branchInputSchema).min(1).optional().nullable(),
  })
  .superRefine((value, ctx) => {
    if (!value.userId && !value.ownerUser) {
      ctx.addIssue({
        code: "custom",
        message: "Informe userId ou ownerUser para registar o tenant.",
        path: ["ownerUser"],
      });
    }

    const key = normalizeTenantSlug(value.tenantName);
    if (!key || key.length < 2) {
      ctx.addIssue({
        code: "custom",
        message:
          "Não foi possível gerar o identificador a partir do nome do tenant.",
        path: ["tenantName"],
      });
    }

    if (value.nuit && !isValidNuit(value.nuit)) {
      ctx.addIssue({
        code: "custom",
        message: "NUIT inválido. Deve conter exactamente 9 dígitos.",
        path: ["nuit"],
      });
    }

    const hasBranches =
      (value.branches && value.branches.length > 0) ||
      Boolean(value.branchName?.trim());
    if (!hasBranches) {
      ctx.addIssue({
        code: "custom",
        message: "Informe pelo menos uma Branch.",
        path: ["branches"],
      });
    }
  });

const registerTenantQuerySchema = z.object({
  async: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
});

const listTenantsQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
});

const updateTenantSchema = z
  .object({
    tenantName: z.string().trim().min(1).optional(),
    nuit: z.string().trim().optional().nullable(),
    email: z.string().trim().pipe(z.email()).optional().nullable(),
    telefone: z.string().trim().optional().nullable(),
    endereco: z.string().trim().optional().nullable(),
  })
  .refine(
    (v) => {
      if (v.nuit && !isValidNuit(v.nuit)) return false;
      return true;
    },
    { message: "NUIT inválido. Deve conter exactamente 9 dígitos.", path: ["nuit"] },
  );

const updateOwnerPasswordSchema = z.object({
  newPassword: z.string().min(6, "A nova senha deve ter pelo menos 6 caracteres."),
});

function parseCentralRole(input: unknown, fallback: Role): Role {
  if (input === Role.superadmin || input === Role.admin || input === Role.usuario) {
    return input;
  }
  if (typeof input === "string") {
    const value = input.toLowerCase();
    if (value === "superadmin") return Role.superadmin;
    if (value === "admin") return Role.admin;
    if (value === "usuario") return Role.usuario;
  }
  return fallback;
}

function isPublicRegistrationAllowed(): boolean {
  return process.env.PUBLIC_TENANT_REGISTRATION !== "false";
}

const tenantListSelect = {
  id: true,
  ownerUserId: true,
  tenantName: true,
  tenantKey: true,
  nuit: true,
  email: true,
  endereco: true,
  status: true,
  country: true,
  createdAt: true,
  branches: {
    select: {
      id: true,
      code: true,
      name: true,
      active: true,
      isHeadOffice: true,
    },
    orderBy: { createdAt: "asc" as const },
  },
  subscriptions: {
    where: { deletedAt: null },
    orderBy: { createdAt: "desc" as const },
    take: 1,
    select: {
      status: true,
      nextBillingAt: true,
      currentPeriodEnd: true,
      plan: {
        select: {
          name: true,
          slug: true,
          monthlyPrice: true,
          extraBranchPrice: true,
        },
      },
    },
  },
};

function mapTenantRecord(tenant: any) {
  const currentSub = tenant.subscriptions?.[0] ?? null;
  const plan = currentSub?.plan ?? null;
  const { subscriptions: _subscriptions, ...rest } = tenant;

  return {
    ...rest,
    id: tenant.id.toString(),
    ownerUserId: tenant.ownerUserId.toString(),
    tenantKey: tenant.tenantKey,
    tenantName: tenant.tenantName,
    branches: tenant.branches.map((branch: any) => ({
      ...branch,
      id: branch.id.toString(),
    })),
    subscription: currentSub
      ? {
          status: currentSub.status,
          planName: plan?.name ?? null,
          planSlug: plan?.slug ?? null,
          monthlyPrice: plan?.monthlyPrice ?? null,
          extraBranchPrice: plan?.extraBranchPrice ?? null,
          nextBillingAt: currentSub.nextBillingAt,
          currentPeriodEnd: currentSub.currentPeriodEnd,
        }
      : null,
  };
}

export class CentralTenantController {
  async list(auth: CentralAuthContext, url: URL): Promise<Response> {
    const prisma = prismaCentral as any;
    const query = parseSearchParams(url, listTenantsQuerySchema);
    const search = query.q?.trim();

    const accessWhere =
      auth.role === Role.superadmin
        ? { deletedAt: null }
        : {
            deletedAt: null,
            id: {
              in: auth.payload.tenants.map((tenant) => BigInt(tenant.id)),
            },
          };

    const where = {
      ...accessWhere,
      ...(search
        ? {
            OR: [
              { tenantKey: { contains: search } },
              { tenantName: { contains: search } },
              { email: { contains: search } },
              { nuit: { contains: search } },
            ],
          }
        : {}),
    };

    // Sem page → lista completa (dashboard / agregações).
    if (query.page == null) {
      const tenants = await prisma.tenant.findMany({
        where,
        orderBy: { createdAt: "desc" },
        select: tenantListSelect,
      });
      return Response.json(serializeForJson(tenants.map(mapTenantRecord)));
    }

    const page = Math.max(1, query.page);
    const pageSize = Math.min(100, Math.max(1, query.pageSize ?? 20));

    const [totalCount, rows] = await prisma.$transaction([
      prisma.tenant.count({ where }),
      prisma.tenant.findMany({
        where,
        orderBy: { createdAt: "desc" },
        select: tenantListSelect,
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);

    const items = rows.slice(0, pageSize).map(mapTenantRecord);
    return success(items, 200, {
      page,
      pageSize,
      hasMore: rows.length > pageSize,
      totalCount,
    });
  }

  async getById(_auth: CentralAuthContext, tenantId: string): Promise<Response> {
    const prisma = prismaCentral as any;
    const tenant = await prisma.tenant.findFirst({
      where: { id: BigInt(tenantId), deletedAt: null },
      select: tenantListSelect,
    });

    if (!tenant) {
      return Response.json({ error: "Tenant not found" }, { status: 404 });
    }

    return Response.json(serializeForJson(mapTenantRecord(tenant)));
  }

  async register(req: Request, url: URL, auth: CentralAuthContext | null): Promise<Response> {
    const hasBearer = Boolean(req.headers.get("Authorization")?.startsWith("Bearer "));

    if (!hasBearer && !isPublicRegistrationAllowed()) {
      return Response.json(
        {
          error: {
            message:
              "Registo público desactivado. Autentique-se ou defina PUBLIC_TENANT_REGISTRATION=true.",
          },
        },
        { status: 401 },
      );
    }

    if (hasBearer && auth && auth.role !== Role.superadmin && !isPublicRegistrationAllowed()) {
      return Response.json(
        { error: { message: "Apenas superadmin pode criar tenants." } },
        { status: 403 },
      );
    }

    const body = await parseJsonBody(req, registerTenantSchema);
    const tenantName = body.tenantName.trim();
    const tenantKey = normalizeTenantSlug(tenantName);

    let ownerUserId = body.userId;
    if (!ownerUserId) {
      const ownerUser = body.ownerUser!;

      const existingOwner = await prismaCentral.user.findUnique({
        where: { email: ownerUser.email.trim().toLowerCase() },
      });
      if (existingOwner) {
        return Response.json(
          {
            error: {
              message: `Já existe um utilizador central com o e-mail ${ownerUser.email}.`,
            },
          },
          { status: 409 },
        );
      }

      const hashedPassword = await bcrypt.hash(ownerUser.password, 10);
      const createdUser = await prismaCentral.user.create({
        data: {
          name: ownerUser.name.trim() || tenantName,
          email: ownerUser.email.trim().toLowerCase(),
          password: hashedPassword,
          role: parseCentralRole(ownerUser.role, Role.admin),
        },
      });
      ownerUserId = createdUser.id.toString();
    }

    const branches =
      body.branches && body.branches.length > 0
        ? body.branches.map((b) => ({ name: b.name.trim() }))
        : [{ name: body.branchName?.trim() || tenantName }];

    const tenantRegistrationPayload = {
      tenantName,
      tenantKey,
      userId: ownerUserId,
      email: body.email ?? body.ownerUser?.email ?? null,
      endereco: body.endereco ?? null,
      nuit: body.nuit ?? null,
      telefone: body.telefone ?? null,
      planSlug: body.planSlug ?? "starter",
      status: body.status ?? "trial",
      billingPeriodMonths: body.billingPeriodMonths ?? 1,
      branches,
    };

    const { async: runAsync = false } = parseSearchParams(url, registerTenantQuerySchema);
    if (runAsync) {
      const queue = new JobQueueService();
      const job = await queue.enqueue("tenant.register", tenantRegistrationPayload);
      return Response.json(
        serializeForJson({
          status: "queued",
          jobId: job.id,
          type: job.type,
          queuedAt: job.createdAt,
        }),
        { status: 202 },
      );
    }

    try {
      const createTenant = new CreateTenantUseCase();
      const result = await createTenant.execute(tenantRegistrationPayload);
      return Response.json(serializeForJson(result), { status: 201 });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Falha ao criar tenant.";
      const conflict =
        message.includes("Já existe") ||
        message.toLowerCase().includes("unique") ||
        message.includes("Duplicate");
      return Response.json(
        { error: { message } },
        { status: conflict ? 409 : 400 },
      );
    }
  }

  async update(auth: CentralAuthContext, tenantId: string, req: Request): Promise<Response> {
    if (auth.role !== Role.superadmin) {
      return Response.json({ error: { message: "Apenas superadmin pode editar tenants." } }, { status: 403 });
    }

    const body = await parseJsonBody(req, updateTenantSchema);
    const prisma = prismaCentral as any;

    const existing = await prisma.tenant.findFirst({
      where: { id: BigInt(tenantId), deletedAt: null },
      select: { id: true, tenantName: true, nuit: true, email: true, telefone: true, endereco: true },
    });
    if (!existing) {
      return Response.json({ error: { message: "Tenant não encontrado." } }, { status: 404 });
    }

    const data: Record<string, unknown> = {};
    if (body.tenantName !== undefined) data.tenantName = body.tenantName;
    if (body.nuit !== undefined) data.nuit = body.nuit;
    if (body.email !== undefined) data.email = body.email;
    if (body.telefone !== undefined) data.telefone = body.telefone;
    if (body.endereco !== undefined) data.endereco = body.endereco;

    if (Object.keys(data).length === 0) {
      return Response.json({ error: { message: "Nenhum campo para actualizar." } }, { status: 400 });
    }

    const updated = await prisma.tenant.update({
      where: { id: BigInt(tenantId) },
      data,
      select: tenantListSelect,
    });

    await writeCentralAuditLog({
      tenantId: BigInt(tenantId),
      userId: BigInt(auth.userId),
      action: "TENANT_UPDATE",
      entity: "Tenant",
      entityId: tenantId,
      oldData: serializeForJson(existing),
      newData: serializeForJson(data),
    });

    return Response.json(serializeForJson(mapTenantRecord(updated)));
  }

  async deleteTenant(auth: CentralAuthContext, tenantId: string): Promise<Response> {
    if (auth.role !== Role.superadmin) {
      return Response.json(
        { error: { message: "Apenas superadmin pode eliminar tenants." } },
        { status: 403 },
      );
    }

    try {
      await new DeleteTenantUseCase().execute({
        tenantId,
        userId: auth.userId,
      });
      return new Response(null, { status: 204 });
    } catch (error) {
      return controllerErrorResponse(error, 500);
    }
  }

  async updateOwnerPassword(auth: CentralAuthContext, tenantId: string, req: Request): Promise<Response> {
    if (auth.role !== Role.superadmin) {
      return Response.json(
        { error: { message: "Apenas superadmin pode alterar a senha do proprietário." } },
        { status: 403 },
      );
    }

    try {
      const body = await parseJsonBody(req, updateOwnerPasswordSchema);
      const prisma = prismaCentral as any;

      const tenant = await prisma.tenant.findFirst({
        where: { id: BigInt(tenantId), deletedAt: null },
        select: { id: true, tenantName: true, ownerUserId: true },
      });
      if (!tenant) {
        return Response.json({ error: { message: "Tenant não encontrado." } }, { status: 404 });
      }

      const hashedPassword = await bcrypt.hash(body.newPassword, 10);
      await prisma.user.update({
        where: { id: tenant.ownerUserId },
        data: { password: hashedPassword },
      });

      await writeCentralAuditLog({
        tenantId: BigInt(tenantId),
        userId: BigInt(auth.userId),
        action: "TENANT_OWNER_PASSWORD_CHANGE",
        entity: "User",
        entityId: tenant.ownerUserId.toString(),
        newData: {
          tenantId,
          tenantName: tenant.tenantName,
          note: "password changed by superadmin",
        },
      });

      return Response.json({ message: "Senha do proprietário actualizada com sucesso." });
    } catch (error) {
      return controllerErrorResponse(error, 500);
    }
  }
}

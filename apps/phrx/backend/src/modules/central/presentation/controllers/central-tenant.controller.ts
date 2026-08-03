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
import type { CentralAuthContext } from "../../../../shared/http/central-auth";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { parseJsonBody, parseSearchParams } from "../../../../shared/http/request-validation";

const ownerUserSchema = z.object({
  name: z.string().trim().min(1),
  email: z.string().trim().pipe(z.email()),
  password: z.string().min(6),
  role: z.enum(["superadmin", "admin", "usuario"]).optional(),
});

const registerTenantSchema = z
  .object({
    nomeEmpresa: z.string().trim().min(1, "Nome da empresa é obrigatório"),
    nomeTenant: z.string().trim().min(1, "Slug / identificador do tenant é obrigatório"),
    slug: z.string().trim().min(1).optional(),
    adminName: z.string().trim().min(1),
    adminEmail: z.string().trim().pipe(z.email()),
    adminPassword: z.string().min(1).optional(),
    userId: z.string().trim().min(1).optional(),
    ownerUser: ownerUserSchema.optional(),
    email: z.string().trim().pipe(z.email()).optional().nullable(),
    endereco: z.string().trim().min(1).optional().nullable(),
    nuit: z.string().trim().min(1).optional().nullable(),
    telefone: z.string().trim().min(1).optional().nullable(),
    planSlug: z.enum(["base", "starter", "enterprise"]).optional().nullable(),
    status: z.enum(["trial", "ativo"]).optional().nullable(),
    branchName: z.string().trim().min(1).optional().nullable(),
    branchCode: z.string().trim().min(1).optional().nullable(),
    branchEndereco: z.string().trim().min(1).optional().nullable(),
    branchContacto: z.string().trim().min(1).optional().nullable(),
  })
  .superRefine((value, ctx) => {
    if (!value.userId && !value.ownerUser) {
      ctx.addIssue({
        code: "custom",
        message: "Informe userId ou ownerUser para registar o tenant.",
        path: ["ownerUser"],
      });
    }

    const slugSource = value.slug?.trim() || value.nomeTenant;
    const slug = normalizeTenantSlug(slugSource);
    if (!slug || slug.length < 2) {
      ctx.addIssue({
        code: "custom",
        message: "Slug inválido. Use letras, números ou underscore (mín. 2).",
        path: ["nomeTenant"],
      });
    }

    if (value.nuit && !isValidNuit(value.nuit)) {
      ctx.addIssue({
        code: "custom",
        message: "NUIT inválido. Deve conter exactamente 9 dígitos.",
        path: ["nuit"],
      });
    }
  });

const registerTenantQuerySchema = z.object({
  async: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
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
  ownerId: true,
  companyName: true,
  name: true,
  nuit: true,
  email: true,
  endereco: true,
  status: true,
  createdAt: true,
  branches: {
    select: {
      id: true,
      code: true,
      name: true,
      active: true,
    },
    orderBy: { createdAt: "asc" as const },
  },
};

function mapTenantRecord(tenant: any) {
  return {
    ...tenant,
    id: tenant.id.toString(),
    ownerId: tenant.ownerId.toString(),
    branches: tenant.branches.map((branch: any) => ({
      ...branch,
      id: branch.id.toString(),
    })),
  };
}

export class CentralTenantController {
  async list(auth: CentralAuthContext): Promise<Response> {
    const prisma = prismaCentral as any;

    const where =
      auth.role === Role.superadmin
        ? { deletedAt: null }
        : {
            deletedAt: null,
            id: {
              in: auth.payload.tenants.map((tenant) => BigInt(tenant.id)),
            },
          };

    const tenants = await prisma.tenant.findMany({
      where,
      orderBy: { createdAt: "desc" },
      select: tenantListSelect,
    });

    return Response.json(serializeForJson(tenants.map(mapTenantRecord)));
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
    const slug = normalizeTenantSlug(body.slug?.trim() || body.nomeTenant);

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
          name: ownerUser.name,
          email: ownerUser.email.trim().toLowerCase(),
          password: hashedPassword,
          role: parseCentralRole(ownerUser.role, Role.admin),
        },
      });
      ownerUserId = createdUser.id.toString();
    }

    const tenantRegistrationPayload = {
      nomeEmpresa: body.nomeEmpresa,
      nomeTenant: slug,
      adminName: body.adminName,
      adminEmail: body.adminEmail,
      adminPassword: body.adminPassword ?? "",
      userId: ownerUserId,
      email: body.email ?? null,
      endereco: body.endereco ?? null,
      nuit: body.nuit ?? null,
      telefone: body.telefone ?? null,
      planSlug: body.planSlug ?? "base",
      status: body.status ?? "trial",
      branchName: body.branchName ?? null,
      branchCode: body.branchCode ?? "HQ",
      branchEndereco: body.branchEndereco ?? null,
      branchContacto: body.branchContacto ?? null,
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
}

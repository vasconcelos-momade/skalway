import { z } from "zod";
import { Role } from "../../../../infrastructure/prisma/central/generated/central";
import { prismaCentralUnscoped } from "../../../../infrastructure/prisma/prisma-central.service";
import { ActivateBranchUseCase } from "../../tenants/application/use-cases/activate-branch.use-case";
import { CreateBranchUseCase } from "../../tenants/application/use-cases/create-branch.use-case";
import { DeactivateBranchUseCase } from "../../tenants/application/use-cases/deactivate-branch.use-case";
import { ListBranchesUseCase } from "../../tenants/application/use-cases/list-branches.use-case";
import type { CentralAuthContext } from "../../../../shared/http/central-auth";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { parseJsonBody, parseSearchParams } from "../../../../shared/http/request-validation";
import {
  pagedSuccess,
  resolvePage,
  resolvePageSize,
  slicePage,
} from "../helpers/paged-response";

const createBranchSchema = z.object({
  name: z.string().trim().min(1),
});

const branchToggleSchema = z.object({
  reason: z.string().trim().min(1).optional().nullable(),
});

const listBranchesQuerySchema = z.object({
  includeInactive: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
});

const listAllBranchesQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
  includeInactive: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
});

export class CentralBranchController {
  async listAll(auth: CentralAuthContext, url: URL): Promise<Response> {
    const query = parseSearchParams(url, listAllBranchesQuerySchema);
    const prisma = prismaCentralUnscoped as any;
    const search = query.q?.trim();
    const includeInactive = query.includeInactive === true;
    const page = resolvePage(query.page ?? 1);
    const pageSize = resolvePageSize(query.pageSize);

    const tenantFilter =
      auth.role === Role.superadmin
        ? { deletedAt: null }
        : {
            deletedAt: null,
            id: {
              in: auth.payload.tenants.map((tenant) => BigInt(tenant.id)),
            },
          };

    const where = {
      deletedAt: null,
      ...(includeInactive ? {} : { active: true }),
      tenant: tenantFilter,
      ...(search
        ? {
            OR: [
              { name: { contains: search } },
              { code: { contains: search } },
              { tenant: { tenantKey: { contains: search } } },
              { tenant: { tenantName: { contains: search } } },
            ],
          }
        : {}),
    };

    const [totalCount, rows] = await prisma.$transaction([
      prisma.branch.count({ where }),
      prisma.branch.findMany({
        where,
        select: {
          id: true,
          code: true,
          name: true,
          active: true,
          isHeadOffice: true,
          lastSyncAt: true,
          tenant: {
            select: {
              id: true,
              tenantKey: true,
              tenantName: true,
            },
          },
        },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);

    const { items, hasMore } = slicePage(rows, page, pageSize);
    const mapped = items.map((row: any) => ({
      tenantId: row.tenant.id.toString(),
      tenantKey: row.tenant.tenantKey,
      tenantName: row.tenant.tenantName,
      branch: {
        id: row.id.toString(),
        code: row.code,
        name: row.name,
        active: row.active,
        isHeadOffice: row.isHeadOffice,
        lastSyncAt: row.lastSyncAt,
      },
    }));

    return pagedSuccess(mapped, { page, pageSize, hasMore, totalCount });
  }

  async list(tenantId: string, url: URL): Promise<Response> {
    const { includeInactive = false } = listBranchesQuerySchema.parse(
      Object.fromEntries(url.searchParams.entries()),
    );
    const useCase = new ListBranchesUseCase();
    const branches = await useCase.execute({ tenantId, includeInactive });
    return Response.json(serializeForJson(branches));
  }

  async create(tenantId: string, req: Request): Promise<Response> {
    const body = await parseJsonBody(req, createBranchSchema);

    const useCase = new CreateBranchUseCase();
    const branch = await useCase.execute({
      tenantId,
      name: body.name,
    });

    return Response.json(serializeForJson(branch), { status: 201 });
  }

  async deactivate(
    tenantId: string,
    branchId: string,
    req: Request,
    userId?: string | null,
  ): Promise<Response> {
    const body = await parseJsonBody(req, branchToggleSchema);
    const useCase = new DeactivateBranchUseCase();
    const branch = await useCase.execute({
      tenantId,
      branchId,
      reason: body.reason ?? null,
      userId: userId ?? null,
    });
    return Response.json(serializeForJson(branch));
  }

  async activate(
    tenantId: string,
    branchId: string,
    req: Request,
    userId?: string | null,
  ): Promise<Response> {
    const body = await parseJsonBody(req, branchToggleSchema);
    const useCase = new ActivateBranchUseCase();
    const branch = await useCase.execute({
      tenantId,
      branchId,
      reason: body.reason ?? null,
      userId: userId ?? null,
    });
    return Response.json(serializeForJson(branch));
  }
}

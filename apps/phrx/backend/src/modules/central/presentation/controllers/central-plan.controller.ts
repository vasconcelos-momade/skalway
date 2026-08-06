import { z } from "zod";
import { prismaCentral } from "../../../../infrastructure/prisma/prisma-central.service";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { parseJsonBody, parseSearchParams } from "../../../../shared/http/request-validation";
import {
  listSuccess,
  pagedSuccess,
  resolvePage,
  resolvePageSize,
  slicePage,
} from "../helpers/paged-response";

const createPlanSchema = z.object({
  name: z.string().trim().min(1),
  slug: z
    .string()
    .trim()
    .min(2)
    .regex(/^[a-z0-9_-]+$/, "Slug inválido (a-z, 0-9, _ ou -)"),
  monthlyPrice: z.coerce.number().min(0),
  includedBranches: z.coerce.number().int().min(1).default(1),
  extraBranchPrice: z.coerce.number().min(0).default(0),
  isEnterprise: z.coerce.boolean().optional().default(false),
  billingIntervalMonths: z.coerce.number().int().min(1).max(36).default(1),
  trialDays: z.coerce.number().int().min(0).max(365).default(14),
  active: z.coerce.boolean().optional().default(true),
});

const updatePlanSchema = createPlanSchema.partial().extend({
  slug: z
    .string()
    .trim()
    .min(2)
    .regex(/^[a-z0-9_-]+$/, "Slug inválido (a-z, 0-9, _ ou -)")
    .optional(),
});

const listPlansQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
  includeInactive: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
});

function mapPlan(plan: any) {
  return {
    id: plan.id,
    name: plan.name,
    slug: plan.slug,
    monthlyPrice: Number(plan.monthlyPrice),
    includedBranches: plan.includedBranches,
    extraBranchPrice: Number(plan.extraBranchPrice),
    isEnterprise: plan.isEnterprise,
    billingIntervalMonths: plan.billingIntervalMonths,
    trialDays: plan.trialDays,
    active: plan.active,
    createdAt: plan.createdAt,
    updatedAt: plan.updatedAt,
  };
}

export class CentralPlanController {
  async list(url: URL): Promise<Response> {
    const query = parseSearchParams(url, listPlansQuerySchema);
    const includeInactive = query.includeInactive === true;
    const search = query.q?.trim();
    const prisma = prismaCentral as any;

    const where = {
      deletedAt: null,
      ...(includeInactive ? {} : { active: true }),
      ...(search
        ? {
            OR: [
              { name: { contains: search } },
              { slug: { contains: search } },
            ],
          }
        : {}),
    };

    if (query.page == null) {
      const plans = await prisma.plan.findMany({
        where,
        orderBy: [{ isEnterprise: "asc" }, { monthlyPrice: "asc" }],
      });
      return listSuccess(plans.map(mapPlan));
    }

    const page = resolvePage(query.page);
    const pageSize = resolvePageSize(query.pageSize);
    const [totalCount, rows] = await prisma.$transaction([
      prisma.plan.count({ where }),
      prisma.plan.findMany({
        where,
        orderBy: [{ isEnterprise: "asc" }, { monthlyPrice: "asc" }],
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);
    const { items, hasMore } = slicePage(rows, page, pageSize);
    return pagedSuccess(items.map(mapPlan), {
      page,
      pageSize,
      hasMore,
      totalCount,
    });
  }

  async getById(planId: string): Promise<Response> {
    const prisma = prismaCentral as any;
    const plan = await prisma.plan.findFirst({
      where: { id: Number(planId), deletedAt: null },
    });
    if (!plan) {
      return Response.json({ error: { message: "Plano não encontrado." } }, { status: 404 });
    }
    return Response.json(serializeForJson(mapPlan(plan)));
  }

  async create(req: Request): Promise<Response> {
    const body = await parseJsonBody(req, createPlanSchema);
    const prisma = prismaCentral as any;

    const existing = await prisma.plan.findFirst({
      where: { slug: body.slug, deletedAt: null },
    });
    if (existing) {
      return Response.json(
        { error: { message: `Já existe um plano com o slug "${body.slug}".` } },
        { status: 409 },
      );
    }

    const plan = await prisma.plan.create({
      data: {
        name: body.name,
        slug: body.slug,
        monthlyPrice: body.monthlyPrice,
        includedBranches: body.includedBranches,
        extraBranchPrice: body.extraBranchPrice,
        isEnterprise: body.isEnterprise ?? false,
        billingIntervalMonths: body.billingIntervalMonths,
        trialDays: body.trialDays,
        active: body.active ?? true,
      },
    });

    return Response.json(serializeForJson(mapPlan(plan)), { status: 201 });
  }

  async update(planId: string, req: Request): Promise<Response> {
    const body = await parseJsonBody(req, updatePlanSchema);
    const prisma = prismaCentral as any;
    const id = Number(planId);

    const current = await prisma.plan.findFirst({
      where: { id, deletedAt: null },
    });
    if (!current) {
      return Response.json({ error: { message: "Plano não encontrado." } }, { status: 404 });
    }

    if (body.slug && body.slug !== current.slug) {
      const clash = await prisma.plan.findFirst({
        where: { slug: body.slug, deletedAt: null, NOT: { id } },
      });
      if (clash) {
        return Response.json(
          { error: { message: `Já existe um plano com o slug "${body.slug}".` } },
          { status: 409 },
        );
      }
    }

    const plan = await prisma.plan.update({
      where: { id },
      data: {
        ...(body.name != null ? { name: body.name } : {}),
        ...(body.slug != null ? { slug: body.slug } : {}),
        ...(body.monthlyPrice != null ? { monthlyPrice: body.monthlyPrice } : {}),
        ...(body.includedBranches != null
          ? { includedBranches: body.includedBranches }
          : {}),
        ...(body.extraBranchPrice != null
          ? { extraBranchPrice: body.extraBranchPrice }
          : {}),
        ...(body.isEnterprise != null ? { isEnterprise: body.isEnterprise } : {}),
        ...(body.billingIntervalMonths != null
          ? { billingIntervalMonths: body.billingIntervalMonths }
          : {}),
        ...(body.trialDays != null ? { trialDays: body.trialDays } : {}),
        ...(body.active != null ? { active: body.active } : {}),
      },
    });

    return Response.json(serializeForJson(mapPlan(plan)));
  }

  async deactivate(planId: string): Promise<Response> {
    const prisma = prismaCentral as any;
    const id = Number(planId);
    const current = await prisma.plan.findFirst({
      where: { id, deletedAt: null },
    });
    if (!current) {
      return Response.json({ error: { message: "Plano não encontrado." } }, { status: 404 });
    }

    const plan = await prisma.plan.update({
      where: { id },
      data: { active: false },
    });

    return Response.json(serializeForJson(mapPlan(plan)));
  }
}

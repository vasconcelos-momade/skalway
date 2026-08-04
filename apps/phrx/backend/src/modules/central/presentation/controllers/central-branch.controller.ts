import { z } from "zod";
import { ActivateBranchUseCase } from "../../tenants/application/use-cases/activate-branch.use-case";
import { CreateBranchUseCase } from "../../tenants/application/use-cases/create-branch.use-case";
import { DeactivateBranchUseCase } from "../../tenants/application/use-cases/deactivate-branch.use-case";
import { ListBranchesUseCase } from "../../tenants/application/use-cases/list-branches.use-case";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { parseJsonBody } from "../../../../shared/http/request-validation";

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

export class CentralBranchController {
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

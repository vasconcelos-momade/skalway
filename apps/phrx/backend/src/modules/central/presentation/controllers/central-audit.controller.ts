import { z } from "zod";
import { success } from "../../../../shared/http/api-response";
import { controllerErrorResponse } from "../../../../shared/http/controller-error";
import { parseSearchParams } from "../../../../shared/http/request-validation";
import { ListCentralAuditLogsUseCase } from "../../audit/application/list-central-audit-logs.use-case";

const listAuditQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  entity: z.string().trim().min(1).optional(),
  action: z.string().trim().min(1).optional(),
  tenantId: z.string().regex(/^\d+$/).optional(),
  userId: z.string().regex(/^\d+$/).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
});

export class CentralAuditController {
  private readonly listUseCase = new ListCentralAuditLogsUseCase();

  async listLogs(url: URL): Promise<Response> {
    try {
      const query = parseSearchParams(url, listAuditQuerySchema);
      const result = await this.listUseCase.execute(query);
      return success(result.items, 200, {
        page: result.page,
        pageSize: result.pageSize,
        hasMore: result.hasMore,
        totalCount: result.totalCount,
      });
    } catch (error: any) {
      return controllerErrorResponse(error, 500);
    }
  }
}

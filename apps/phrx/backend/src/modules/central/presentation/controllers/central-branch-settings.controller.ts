import { BranchSettingService } from "../../branch-settings";
import { updateBranchSettingsSchema, branchIdParamSchema } from "../../branch-settings/application/dto/branch-setting.dto";
import { controllerErrorResponse } from "../../../../shared/http/controller-error";
import {
  parseJsonBody,
  parseRouteParams,
} from "../../../../shared/http/request-validation";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import type { RouteContext } from "../../../../shared/http/router";
import { getTenantAuth } from "../../../../shared/http/auth-middlewares";

/**
 * Configurações da filial activa (BranchSetting).
 * Isoladas de CentralSettings e TenantSetting.
 */
export class CentralBranchSettingsController {
  private auditUserId(auth: ReturnType<typeof getTenantAuth>) {
    return auth.centralUserId ?? auth.userId;
  }

  private resolveBranchId(auth: ReturnType<typeof getTenantAuth>, paramBranchId?: string) {
    const contextBranchId = String(auth.branchId);
    if (paramBranchId && paramBranchId !== contextBranchId) {
      throw new Error(
        "branchId do pedido não corresponde à filial do contexto activo",
      );
    }
    return contextBranchId;
  }

  async list(context: RouteContext): Promise<Response> {
    try {
      const auth = getTenantAuth(context);
      const params = context.params?.branchId
        ? parseRouteParams(context.params, branchIdParamSchema)
        : { branchId: String(auth.branchId) };
      const branchId = this.resolveBranchId(auth, params.branchId);
      const result = await new BranchSettingService().list(auth.tenantId, branchId);
      return Response.json(serializeForJson(result));
    } catch (error: unknown) {
      return controllerErrorResponse(error);
    }
  }

  async update(context: RouteContext): Promise<Response> {
    try {
      const auth = getTenantAuth(context);
      const params = context.params?.branchId
        ? parseRouteParams(context.params, branchIdParamSchema)
        : { branchId: String(auth.branchId) };
      const branchId = this.resolveBranchId(auth, params.branchId);
      const body = await parseJsonBody(context.req, updateBranchSettingsSchema);
      const entries = Object.entries(body.settings).map(([key, value]) => ({
        key,
        value,
      }));
      const userId = this.auditUserId(auth);
      await new BranchSettingService().updateMany(
        auth.tenantId,
        branchId,
        entries,
        { userId: userId ? BigInt(userId) : null },
      );
      const result = await new BranchSettingService().list(auth.tenantId, branchId);
      return Response.json(serializeForJson(result));
    } catch (error: unknown) {
      return controllerErrorResponse(error);
    }
  }

  async invoiceProfile(context: RouteContext): Promise<Response> {
    try {
      const auth = getTenantAuth(context);
      const params = context.params?.branchId
        ? parseRouteParams(context.params, branchIdParamSchema)
        : { branchId: String(auth.branchId) };
      const branchId = this.resolveBranchId(auth, params.branchId);
      const result = await new BranchSettingService().getInvoiceProfile(
        auth.tenantId,
        branchId,
      );
      return Response.json(serializeForJson(result));
    } catch (error: unknown) {
      return controllerErrorResponse(error);
    }
  }
}

import { CashierDashboardUseCase } from "../application/cashier-dashboard.use-case";
import { ExecutiveDashboardUseCase } from "../application/executive-dashboard.use-case";
import { FinanceDashboardUseCase } from "../application/finance-dashboard.use-case";
import { PharmacyDashboardUseCase } from "../application/pharmacy-dashboard.use-case";
import { StockDashboardUseCase } from "../application/stock-dashboard.use-case";
import {
  cashierDashboardTableQuerySchema,
  dashboardPeriodQuerySchema,
  executiveDashboardTableQuerySchema,
  financeDashboardTableQuerySchema,
  pharmacyDashboardTableQuerySchema,
  stockDashboardTableQuerySchema,
} from "../application/dashboard.dto";
import { parseSearchParams } from "../../../../shared/http/request-validation";
import { controllerErrorResponse } from "../../../../shared/http/controller-error";
import { resolveDataScopeForUser } from "../../shared/data-scope";

export class DashboardController {
  private executiveUseCase = new ExecutiveDashboardUseCase();
  private financeUseCase = new FinanceDashboardUseCase();
  private pharmacyUseCase = new PharmacyDashboardUseCase();
  private stockUseCase = new StockDashboardUseCase();
  private cashierUseCase = new CashierDashboardUseCase();

  async executive(req: Request) {
    try {
      const query = parseSearchParams(new URL(req.url), dashboardPeriodQuerySchema);
      const result = await this.executiveUseCase.execute(query);
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async finance(req: Request, actorUserId: string) {
    try {
      const query = parseSearchParams(new URL(req.url), dashboardPeriodQuerySchema);
      const scope = await resolveDataScopeForUser({ actorUserId });
      const result = await this.financeUseCase.execute({ ...query, scope });
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async financeTable(req: Request, actorUserId: string) {
    try {
      const query = parseSearchParams(
        new URL(req.url),
        financeDashboardTableQuerySchema,
      );
      const scope = await resolveDataScopeForUser({ actorUserId });
      const result = await this.financeUseCase.listTable({ ...query, scope });
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async pharmacy(req: Request, actorUserId: string) {
    try {
      const query = parseSearchParams(new URL(req.url), dashboardPeriodQuerySchema);
      const scope = await resolveDataScopeForUser({ actorUserId });
      const result = await this.pharmacyUseCase.execute({ ...query, scope });
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async pharmacyTable(req: Request, actorUserId: string) {
    try {
      const query = parseSearchParams(
        new URL(req.url),
        pharmacyDashboardTableQuerySchema,
      );
      const scope = await resolveDataScopeForUser({ actorUserId });
      const result = await this.pharmacyUseCase.listTable({ ...query, scope });
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async executiveTable(req: Request) {
    try {
      const query = parseSearchParams(
        new URL(req.url),
        executiveDashboardTableQuerySchema,
      );
      const result = await this.executiveUseCase.listTable(query);
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async stock(req: Request) {
    try {
      const query = parseSearchParams(new URL(req.url), dashboardPeriodQuerySchema);
      const result = await this.stockUseCase.execute(query);
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async stockTable(req: Request) {
    try {
      const query = parseSearchParams(
        new URL(req.url),
        stockDashboardTableQuerySchema,
      );
      const result = await this.stockUseCase.listTable(query);
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async cashier(req: Request, actorUserId: string) {
    try {
      const query = parseSearchParams(new URL(req.url), dashboardPeriodQuerySchema);
      const scope = await resolveDataScopeForUser({ actorUserId });
      const result = await this.cashierUseCase.execute({ ...query, scope });
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async cashierTable(req: Request, actorUserId: string) {
    try {
      const query = parseSearchParams(
        new URL(req.url),
        cashierDashboardTableQuerySchema,
      );
      const scope = await resolveDataScopeForUser({ actorUserId });
      const result = await this.cashierUseCase.listTable({ ...query, scope });
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  private serialize(data: unknown) {
    return JSON.parse(
      JSON.stringify(data, (_key, value) =>
        typeof value === "bigint" ? value.toString() : value,
      ),
    );
  }
}

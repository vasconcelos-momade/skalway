import { ServicoService } from "../../application/services/servico.service";
import {
  createServicoSchema,
  searchServicosQuerySchema,
  servicoIdParamSchema,
  updateServicoSchema,
} from "../../application/dto/servico.dto";
import {
  parseJsonBody,
  parseSearchParams,
} from "../../../../../shared/http/request-validation";
import { controllerErrorResponse } from "../../../../../shared/http/controller-error";

export class ServicoController {
  private service = new ServicoService();

  async create(req: Request, userId: string) {
    try {
      const body = await parseJsonBody(req, createServicoSchema);
      const result = await this.service.create(body, userId);
      return Response.json(this.serialize(result), { status: 201 });
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async search(req: Request) {
    try {
      const url = new URL(req.url);
      const {
        q,
        includeInactive = false,
        tipoServicoClinico,
        page = 1,
        pageSize = 20,
      } = parseSearchParams(url, searchServicosQuerySchema);

      const result = await this.service.search({
        query: q,
        includeInactive,
        tipoServicoClinico,
        page,
        pageSize,
      });

      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error, 500);
    }
  }

  async stats() {
    try {
      const result = await this.service.getStats();
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error, 500);
    }
  }

  async get(id: string) {
    try {
      const result = await this.service.get(BigInt(id));
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error, 404);
    }
  }

  async update(id: string, req: Request, userId: string) {
    try {
      const body = await parseJsonBody(req, updateServicoSchema);
      const result = await this.service.update(BigInt(id), body, userId);
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async delete(id: string, userId: string) {
    try {
      await this.service.delete(BigInt(id), userId);
      return Response.json({ message: "Serviço eliminado definitivamente" });
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async deactivate(id: string, userId: string) {
    try {
      const result = await this.service.deactivate(BigInt(id), userId);
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  async activate(id: string, userId: string) {
    try {
      const result = await this.service.activate(BigInt(id), userId);
      return Response.json(this.serialize(result));
    } catch (error: any) {
      return controllerErrorResponse(error);
    }
  }

  private serialize(data: any) {
    return JSON.parse(
      JSON.stringify(data, (_key, value) =>
        typeof value === "bigint" ? value.toString() : value,
      ),
    );
  }
}

export { servicoIdParamSchema };

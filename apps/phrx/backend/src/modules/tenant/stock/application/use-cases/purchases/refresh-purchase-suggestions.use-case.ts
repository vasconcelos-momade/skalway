import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import { ValidationApiError } from "../../../../../../shared/http/api-error";
import { startOfDay } from "../../../../dashboard/application/dashboard-date.util";
import {
  refreshAllPurchaseSuggestions,
  resolvePurchaseSuggestionPeriod,
} from "../../../domain/purchase-suggestion.service";
import type { RefreshPurchaseSuggestionsDTO } from "../../dto/suppliers.dto";

export class RefreshPurchaseSuggestionsUseCase {
  async execute(data: RefreshPurchaseSuggestionsDTO) {
    const inicio = startOfDay(new Date(data.dataInicio));
    const fim = startOfDay(new Date(data.dataFim));

    if (Number.isNaN(inicio.getTime()) || Number.isNaN(fim.getTime())) {
      throw new ValidationApiError("Período inválido");
    }
    if (inicio.getTime() > fim.getTime()) {
      throw new ValidationApiError("Data inicial não pode ser posterior à data final");
    }

    const prisma = getPrisma() as any;
    const result = await refreshAllPurchaseSuggestions(prisma, {
      dataInicio: data.dataInicio,
      dataFim: data.dataFim,
    });

    const periodo = resolvePurchaseSuggestionPeriod({
      dataInicio: data.dataInicio,
      dataFim: data.dataFim,
    });

    return {
      message: "Lista de sugestões actualizada",
      processed: result.processed,
      periodoInicio: periodo.periodoInicio,
      periodoFim: periodo.periodoFim,
      periodoLabel: periodo.periodoLabel,
      diasDoPeriodo: periodo.diasDoPeriodo,
    };
  }
}

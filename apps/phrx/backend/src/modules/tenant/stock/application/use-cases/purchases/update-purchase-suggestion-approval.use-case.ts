import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  ForbiddenApiError,
  NotFoundApiError,
  ValidationApiError,
} from "../../../../../../shared/http/api-error";
import { toNumber } from "../../../../dashboard/application/dashboard-date.util";
import { resolveDataScopeForUser } from "../../../../shared/data-scope";
import {
  canApprovePurchaseSuggestionQuantity,
  roundSuggestionInteger,
} from "../../../domain/purchase-suggestion.service";
import type { UpdatePurchaseSuggestionApprovalDTO } from "../../dto/suppliers.dto";

export class UpdatePurchaseSuggestionApprovalUseCase {
  async execute(actorUserId: string, data: UpdatePurchaseSuggestionApprovalDTO) {
    const scope = await resolveDataScopeForUser({ actorUserId });
    const canApprove = canApprovePurchaseSuggestionQuantity(scope.role);

    if (data.quantidadeAprovada != null && !canApprove) {
      throw new ForbiddenApiError(
        "Sem permissão para definir a quantidade aprovada",
      );
    }

    const prisma = getPrisma() as any;
    const produtoId = BigInt(data.produtoId);
    const supplierId = BigInt(data.supplierId);

    const fornecedor = await prisma.fornecedor.findFirst({
      where: { id: supplierId, deletedAt: null, ativo: true },
      select: { id: true },
    });
    if (!fornecedor) {
      throw new ValidationApiError("Fornecedor não encontrado ou inactivo");
    }

    const existing = await prisma.purchaseSuggestion.findUnique({
      where: { produtoId },
      include: {
        produto: { select: { nomeComercial: true, deletedAt: true, ativo: true } },
      },
    });

    if (!existing || existing.produto.deletedAt || !existing.produto.ativo) {
      throw new NotFoundApiError("Sugestão de compra não encontrada");
    }

    const updateData: Record<string, unknown> = { supplierId };
    if (data.quantidadeAprovada != null) {
      const quantidadeAprovada = roundSuggestionInteger(data.quantidadeAprovada);
      if (quantidadeAprovada < 0) {
        throw new ValidationApiError("Quantidade aprovada não pode ser negativa");
      }
      updateData.quantidadeAprovada = quantidadeAprovada;
    }

    const updated = await prisma.purchaseSuggestion.update({
      where: { produtoId },
      data: updateData,
      select: {
        produtoId: true,
        supplierId: true,
        quantidadeSugerida: true,
        quantidadeAprovada: true,
      },
    });

    return {
      message: "Sugestão actualizada",
      produtoId: updated.produtoId.toString(),
      supplierId: updated.supplierId?.toString() ?? null,
      quantidadeSugerida: roundSuggestionInteger(toNumber(updated.quantidadeSugerida)),
      quantidadeAprovada: roundSuggestionInteger(toNumber(updated.quantidadeAprovada)),
    };
  }
}

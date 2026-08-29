import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  ForbiddenApiError,
  ValidationApiError,
} from "../../../../../../shared/http/api-error";
import { toNumber } from "../../../../dashboard/application/dashboard-date.util";
import { resolveDataScopeForUser } from "../../../../shared/data-scope";
import {
  DEFAULT_COVERAGE_DAYS,
  canApprovePurchaseSuggestionQuantity,
  roundSuggestionInteger,
} from "../../../domain/purchase-suggestion.service";
import type { AddManualPurchaseSuggestionDTO } from "../../dto/suppliers.dto";

export class AddManualPurchaseSuggestionUseCase {
  async execute(actorUserId: string, data: AddManualPurchaseSuggestionDTO) {
    const prisma = getPrisma() as any;
    const produtoId = BigInt(data.produtoId);
    const supplierId = BigInt(data.supplierId);

    let quantidadeAprovada = 0;
    if (data.quantidadeAprovada != null) {
      const scope = await resolveDataScopeForUser({ actorUserId });
      if (!canApprovePurchaseSuggestionQuantity(scope.role)) {
        throw new ForbiddenApiError(
          "Sem permissão para definir a quantidade aprovada",
        );
      }

      quantidadeAprovada = roundSuggestionInteger(data.quantidadeAprovada);
      if (quantidadeAprovada < 0) {
        throw new ValidationApiError("Quantidade aprovada não pode ser negativa");
      }
    }

    const [produto, fornecedor] = await Promise.all([
      prisma.produto.findFirst({
        where: { id: produtoId, deletedAt: null, ativo: true },
        select: { id: true, nomeComercial: true },
      }),
      prisma.fornecedor.findFirst({
        where: { id: supplierId, deletedAt: null, ativo: true },
        select: { id: true, nome: true },
      }),
    ]);

    if (!produto) {
      throw new ValidationApiError("Produto não encontrado ou inactivo");
    }
    if (!fornecedor) {
      throw new ValidationApiError("Fornecedor não encontrado ou inactivo");
    }

    const suggestion = await prisma.$transaction(async (tx: any) => {
      await tx.purchaseSuggestion.upsert({
        where: { produtoId },
        create: {
          produtoId,
          supplierId,
          quantidadeAtual: 0,
          estoqueMinimo: 0,
          consumoMedioDiario: 0,
          totalSaidasPeriodo: 0,
          quantidadeSugerida: 0,
          quantidadeAprovada,
          coberturaDias: DEFAULT_COVERAGE_DAYS,
          origem: "MANUAL",
          observacao: data.observacao?.trim() || null,
        },
        update: {
          supplierId,
          origem: "MANUAL",
          quantidadeAtual: 0,
          estoqueMinimo: 0,
          consumoMedioDiario: 0,
          totalSaidasPeriodo: 0,
          quantidadeSugerida: 0,
          quantidadeAprovada,
          observacao: data.observacao?.trim() || null,
        },
      });

      return tx.purchaseSuggestion.findUnique({
        where: { produtoId },
        include: {
          produto: { select: { nomeComercial: true } },
          fornecedor: { select: { id: true, nome: true } },
        },
      });
    });

    if (!suggestion) {
      throw new ValidationApiError("Não foi possível adicionar a sugestão manual");
    }

    return {
      message: "Produto adicionado à sugestão de compras",
      suggestion: {
        id: suggestion.id.toString(),
        produtoId: suggestion.produtoId.toString(),
        produtoNome: suggestion.produto.nomeComercial,
        supplierId: suggestion.supplierId?.toString() ?? null,
        fornecedorNome: suggestion.fornecedor?.nome ?? null,
        quantidadeSugerida: roundSuggestionInteger(
          toNumber(suggestion.quantidadeSugerida),
        ),
        quantidadeAprovada: roundSuggestionInteger(
          toNumber(suggestion.quantidadeAprovada),
        ),
        origem: suggestion.origem,
      },
    };
  }
}

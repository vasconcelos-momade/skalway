import { getPrisma } from "../../../../../infrastructure/prisma/tenant-prisma.factory";
import { ValidationApiError } from "../../../../../shared/http/api-error";
import { ComplianceAuditService } from "../../../../../shared/services/compliance-audit.service";
import {
  normalizeExpiryDate,
  receiveStockEntryItem,
} from "../../domain/purchase-receiving.service";

export interface ReceivePurchaseDTO {
  fornecedorId: string;
  numeroDocumento: string;
  userId: string;
  items: {
    produtoId: string;
    numeroLote: string;
    dataValidade: string;
    quantidade: number;
    precoCompra: number;
    precoVenda?: number;
  }[];
}

/**
 * Recebimento multi-item de compra a fornecedor.
 * Persiste numeroDocumento em EstoqueMovimento.documentoReferencia.
 */
export class ReceivePurchaseUseCase {
  async execute(data: ReceivePurchaseDTO) {
    if (data.items.length === 0) {
      throw new ValidationApiError("Informe pelo menos um item");
    }

    const documentoReferencia = data.numeroDocumento.trim();
    if (!documentoReferencia) {
      throw new ValidationApiError("Número do documento é obrigatório");
    }
    if (documentoReferencia.length > 100) {
      throw new ValidationApiError(
        "Documento de referência não pode exceder 100 caracteres",
      );
    }

    const prisma = getPrisma();

    return await prisma.$transaction(async (tx: any) => {
      const results = [];

      for (const item of data.items) {
        const produtoId = BigInt(item.produtoId);
        const dataValidade = normalizeExpiryDate(item.dataValidade);

        const result = await receiveStockEntryItem(
          tx,
          {
            produtoId,
            fornecedorId: BigInt(data.fornecedorId),
            numeroLote: item.numeroLote,
            dataValidade,
            quantidade: item.quantidade,
            precoCompra: item.precoCompra,
            precoVenda: item.precoVenda ?? null,
            userId: BigInt(data.userId),
            documentoReferencia,
            modo: "COMPRA",
          },
          {
            salePriceMode: "truthy",
          },
        );

        results.push({
          loteId: result.loteId.toString(),
          produtoId: result.produtoId.toString(),
          quantidade: item.quantidade,
          estoqueAnterior: result.estoqueAnterior,
          estoqueFinal: result.estoqueFinal,
        });
      }

      const totalCompra = data.items.reduce(
        (sum, item) => sum + item.quantidade * item.precoCompra,
        0,
      );

      const complianceService = new ComplianceAuditService();
      await complianceService.createImmutableLog(
        {
          userId: data.userId,
          action: "STOCK_RECEIVE_COMPRA",
          entity: "EstoqueMovimento",
          after: {
            modo: "COMPRA",
            origem: "FORNECEDOR",
            fornecedorId: data.fornecedorId,
            documentoReferencia,
            total: totalCompra,
            items: results,
          },
        },
        tx,
      );

      return {
        message: "Compra a fornecedor registada com sucesso",
        numeroDocumento: documentoReferencia,
        documentoReferencia,
        total: totalCompra,
        items: results,
      };
    });
  }
}

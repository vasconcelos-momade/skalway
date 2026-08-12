import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  NotFoundApiError,
  ValidationApiError,
} from "../../../../../../shared/http/api-error";
import { ComplianceAuditService } from "../../../../../../shared/services/compliance-audit.service";
import { receiveStockEntryItem } from "../../../domain/purchase-receiving.service";

export interface EntradaCompraInput {
  produtoId: string;
  fornecedorId: string;
  documentoReferencia: string;
  numeroLote: string;
  dataValidade: string;
  quantidade: number;
  precoCompra: number;
  precoVenda: number;
  userId: string;
}

/**
 * Compra a fornecedor (tipo COMPRA, origem FORNECEDOR).
 * Documento de referência e fornecedor são obrigatórios.
 */
export class EntradaCompraUseCase {
  async execute(data: EntradaCompraInput) {
    if (data.quantidade <= 0) {
      throw new ValidationApiError("Quantidade deve ser superior a zero");
    }

    const documentoReferencia = data.documentoReferencia?.trim() || "";
    if (!documentoReferencia) {
      throw new ValidationApiError(
        "Documento de referência é obrigatório para compra a fornecedor",
      );
    }

    const prisma = getPrisma();

    return prisma.$transaction(async (tx: any) => {
      const produto = await tx.produto.findUnique({
        where: { id: BigInt(data.produtoId) },
      });
      if (!produto || produto.deletedAt != null || !produto.ativo) {
        throw new NotFoundApiError("Produto não encontrado");
      }

      const fornecedor = await tx.fornecedor.findUnique({
        where: { id: BigInt(data.fornecedorId) },
      });
      if (!fornecedor || fornecedor.deletedAt != null || !fornecedor.ativo) {
        throw new NotFoundApiError("Fornecedor não encontrado");
      }

      const result = await receiveStockEntryItem(
        tx,
        {
          produtoId: BigInt(data.produtoId),
          fornecedorId: BigInt(data.fornecedorId),
          numeroLote: data.numeroLote,
          dataValidade: data.dataValidade,
          quantidade: data.quantidade,
          precoCompra: data.precoCompra,
          precoVenda: data.precoVenda,
          userId: BigInt(data.userId),
          documentoReferencia,
          modo: "COMPRA",
        },
        { salePriceMode: "nullish" },
      );

      const complianceService = new ComplianceAuditService();
      await complianceService.createImmutableLog(
        {
          userId: data.userId,
          action: "LOTE_COMPRA",
          entity: "Lote",
          entityId: result.loteId,
          after: {
            modo: "COMPRA",
            origem: result.origem,
            produtoId: result.produtoId.toString(),
            fornecedorId: data.fornecedorId,
            documentoReferencia,
            quantidade: data.quantidade,
            numeroLote: data.numeroLote,
          },
        },
        tx,
      );

      return {
        message: "Compra a fornecedor registada com sucesso",
        loteId: result.loteId.toString(),
        produtoId: result.produtoId.toString(),
        estoqueAnterior: result.estoqueAnterior,
        estoqueFinal: result.estoqueFinal,
        modo: "COMPRA" as const,
        origem: result.origem,
      };
    });
  }
}

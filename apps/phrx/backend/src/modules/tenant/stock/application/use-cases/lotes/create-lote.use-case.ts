import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  NotFoundApiError,
  ValidationApiError,
} from "../../../../../../shared/http/api-error";
import { ComplianceAuditService } from "../../../../../../shared/services/compliance-audit.service";
import {
  receiveStockEntryItem,
  type StockEntryModo,
} from "../../../domain/purchase-receiving.service";

export interface CreateLoteInput {
  produtoId: string;
  /** ENTRADA = estoque inicial; COMPRA = fornecedor. Default COMPRA para compat. */
  modo?: StockEntryModo;
  fornecedorId?: string | null;
  documentoReferencia?: string | null;
  numeroLote: string;
  dataValidade: Date | string;
  quantidadeInicial: number;
  precoCompra: number;
  precoVenda: number;
  userId: string;
}

export class CreateLoteUseCase {
  async execute(data: CreateLoteInput) {
    if (data.quantidadeInicial <= 0) {
      throw new ValidationApiError("Quantidade inicial deve ser superior a zero");
    }

    const modo: StockEntryModo = data.modo === "ENTRADA" ? "ENTRADA" : "COMPRA";
    const documentoReferencia = data.documentoReferencia?.trim() || null;
    const fornecedorIdRaw = data.fornecedorId?.trim() || null;

    if (modo === "COMPRA") {
      if (!fornecedorIdRaw) {
        throw new ValidationApiError("Fornecedor é obrigatório para compra");
      }
      if (!documentoReferencia) {
        throw new ValidationApiError(
          "Documento de referência é obrigatório para compra a fornecedor",
        );
      }
    }

    const prisma = getPrisma() as any;
    const produtoId = BigInt(data.produtoId);
    const fornecedorId = fornecedorIdRaw ? BigInt(fornecedorIdRaw) : null;

    return prisma.$transaction(async (tx: any) => {
      const produto = await tx.produto.findUnique({
        where: { id: produtoId },
      });
      if (!produto || produto.deletedAt != null || !produto.ativo) {
        throw new NotFoundApiError("Produto nao encontrado");
      }

      if (fornecedorId != null) {
        const fornecedor = await tx.fornecedor.findUnique({
          where: { id: fornecedorId },
        });
        if (!fornecedor || fornecedor.deletedAt != null || !fornecedor.ativo) {
          throw new NotFoundApiError("Fornecedor nao encontrado");
        }

        const produtoFornecedor = await tx.produtoFornecedor.findUnique({
          where: {
            produtoId_fornecedorId: {
              produtoId,
              fornecedorId,
            },
          },
        });

        if (!produtoFornecedor) {
          await tx.produtoFornecedor.create({
            data: {
              produtoId,
              fornecedorId,
              precoCompra: data.precoCompra,
            },
          });
        }
      }

      const result = await receiveStockEntryItem(
        tx,
        {
          produtoId,
          fornecedorId,
          numeroLote: data.numeroLote,
          dataValidade: data.dataValidade,
          quantidade: data.quantidadeInicial,
          precoCompra: data.precoCompra,
          precoVenda: data.precoVenda,
          userId: BigInt(data.userId),
          documentoReferencia,
          modo,
        },
        { salePriceMode: "nullish" },
      );

      const complianceService = new ComplianceAuditService();
      await complianceService.createImmutableLog(
        {
          userId: data.userId,
          action: modo === "ENTRADA" ? "LOTE_ENTRADA_INICIAL" : "LOTE_COMPRA",
          entity: "Lote",
          entityId: result.loteId,
          after: {
            modo,
            origem: result.origem,
            produtoId: result.produtoId.toString(),
            fornecedorId: fornecedorIdRaw,
            documentoReferencia,
            quantidade: data.quantidadeInicial,
            numeroLote: data.numeroLote,
          },
        },
        tx,
      );

      return {
        message:
          modo === "ENTRADA"
            ? "Entrada de estoque inicial registada com sucesso"
            : "Lote de compra registado com sucesso",
        loteId: result.loteId.toString(),
        produtoId: result.produtoId.toString(),
        estoqueAnterior: result.estoqueAnterior,
        estoqueFinal: result.estoqueFinal,
        modo,
        origem: result.origem,
      };
    });
  }
}

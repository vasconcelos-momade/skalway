import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import { NotFoundApiError, ValidationApiError } from "../../../../../../shared/http/api-error";
import { receivePurchaseItemStock } from "../../../domain/purchase-receiving.service";

export interface CreateLoteInput {
  produtoId: string;
  fornecedorId: string;
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

    const prisma = getPrisma() as any;
    const produtoId = BigInt(data.produtoId);
    const fornecedorId = BigInt(data.fornecedorId);

    return prisma.$transaction(async (tx: any) => {
      const produto = await tx.produto.findUnique({
        where: { id: produtoId },
      });
      if (!produto || produto.deletedAt != null || !produto.ativo) {
        throw new NotFoundApiError("Produto nao encontrado");
      }

      const fornecedor = await tx.fornecedor.findUnique({
        where: { id: fornecedorId },
      });
      if (!fornecedor || fornecedor.deletedAt != null || !fornecedor.ativo) {
        throw new NotFoundApiError("Fornecedor nao encontrado");
      }

      let produtoFornecedor = await tx.produtoFornecedor.findUnique({
        where: {
          produtoId_fornecedorId: {
            produtoId,
            fornecedorId,
          },
        },
      });

      if (!produtoFornecedor) {
        produtoFornecedor = await tx.produtoFornecedor.create({
          data: {
            produtoId,
            fornecedorId,
            precoCompra: data.precoCompra,
          },
        });
      }

      const result = await receivePurchaseItemStock(
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
        },
        { salePriceMode: "nullish" },
      );

      return {
        message: "Lote criado com sucesso",
        loteId: result.loteId.toString(),
        produtoId: result.produtoId.toString(),
        estoqueAnterior: result.estoqueAnterior,
        estoqueFinal: result.estoqueFinal,
      };
    });
  }
}

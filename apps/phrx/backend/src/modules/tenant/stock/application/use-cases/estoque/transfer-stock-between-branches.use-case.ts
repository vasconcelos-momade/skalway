import { prismaCentralUnscoped } from "../../../../../../infrastructure/prisma/prisma-central.service";
import { TenantPrismaFactory } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import { branchContext } from "../../../../../../shared/context/branch-context";
import {
  NotFoundApiError,
  ValidationApiError,
} from "../../../../../../shared/http/api-error";
import {
  getLoteQuantidadeFromMovements,
  syncLoteStockBalanceCache,
} from "../../../domain/lote-stock.service";
import { syncStockBalanceCache } from "../../../domain/produto-stock.service";
import { getNormalizedExpiryRange } from "../../../domain/purchase-receiving.service";

export const STOCK_TRANSFER_ORIGEM = "TRANSFERENCIA" as const;

export interface TransferStockBetweenBranchesInput {
  produtoId: string;
  loteId: string;
  quantidade: number;
  documentoReferencia: string;
  destinoBranchId: string;
  userId: string;
  centralUserId?: string | null;
  tenantId: string;
  origemBranchId: string;
}

async function resolveDestUserId(
  destPrisma: any,
  sourceUser: {
    email: string | null;
    centralUserId: bigint | null;
  },
  centralUserId?: string | null,
): Promise<bigint> {
  const centralId =
    centralUserId != null && centralUserId !== ""
      ? BigInt(centralUserId)
      : sourceUser.centralUserId;

  if (centralId != null) {
    const byCentral = await destPrisma.user.findFirst({
      where: {
        centralUserId: centralId,
        deletedAt: null,
        active: true,
      },
      select: { id: true },
    });
    if (byCentral) return byCentral.id;
  }

  if (sourceUser.email) {
    const byEmail = await destPrisma.user.findFirst({
      where: {
        email: sourceUser.email,
        deletedAt: null,
        active: true,
      },
      select: { id: true },
    });
    if (byEmail) return byEmail.id;
  }

  const fallback = await destPrisma.user.findFirst({
    where: { deletedAt: null, active: true },
    orderBy: { id: "asc" },
    select: { id: true },
  });
  if (!fallback) {
    throw new ValidationApiError(
      "Filial de destino sem utilizadores activos para registar a transferência",
    );
  }
  return fallback.id;
}

/**
 * Transferência entre filiais:
 * origem → SAIDA + TRANSFERENCIA
 * destino → ENTRADA + TRANSFERENCIA
 * mesmo documentoReferencia.
 */
export class TransferStockBetweenBranchesUseCase {
  async execute(data: TransferStockBetweenBranchesInput) {
    const quantidade = Number(data.quantidade);
    if (!Number.isFinite(quantidade) || quantidade <= 0) {
      throw new ValidationApiError("Quantidade deve ser superior a zero");
    }

    const documentoReferencia = data.documentoReferencia.trim();
    if (!documentoReferencia) {
      throw new ValidationApiError(
        "Documento de referência é obrigatório para transferência",
      );
    }
    if (documentoReferencia.length > 100) {
      throw new ValidationApiError(
        "Documento de referência não pode exceder 100 caracteres",
      );
    }

    if (String(data.destinoBranchId) === String(data.origemBranchId)) {
      throw new ValidationApiError(
        "Filial de destino deve ser diferente da filial de origem",
      );
    }

    const destBranch = await prismaCentralUnscoped.branch.findFirst({
      where: {
        id: BigInt(data.destinoBranchId),
        tenantId: BigInt(data.tenantId),
        deletedAt: null,
        active: true,
      },
      select: {
        id: true,
        name: true,
        dbName: true,
        dbHost: true,
        dbPort: true,
        dbUsername: true,
        dbPasswordCipherText: true,
        dbPasswordIv: true,
        dbPasswordTag: true,
      },
    });
    if (!destBranch) {
      throw new NotFoundApiError("Filial de destino não encontrada ou inactiva");
    }

    const sourcePrisma = TenantPrismaFactory.getClient();
    const produtoId = BigInt(data.produtoId);
    const loteId = BigInt(data.loteId);
    const sourceUserId = BigInt(data.userId);

    const sourceUser = await sourcePrisma.user.findFirst({
      where: { id: sourceUserId, deletedAt: null },
      select: { email: true, centralUserId: true },
    });
    if (!sourceUser) {
      throw new NotFoundApiError("Utilizador de origem não encontrado");
    }

    const sourceSnapshot = await sourcePrisma.$transaction(async (tx: any) => {
      await tx.$executeRaw`SELECT id FROM produtos WHERE id = ${produtoId} FOR UPDATE`;
      await tx.$executeRaw`SELECT id FROM lotes WHERE id = ${loteId} FOR UPDATE`;

      const lote = await tx.lote.findFirst({
        where: { id: loteId, produtoId, deletedAt: null, ativo: true },
        include: {
          produto: {
            select: {
              id: true,
              nomeComercial: true,
              barcode: true,
            },
          },
        },
      });
      if (!lote) {
        throw new NotFoundApiError("Lote não encontrado na filial de origem");
      }

      const estoqueAnterior = await getLoteQuantidadeFromMovements(tx, loteId);
      if (estoqueAnterior < quantidade) {
        throw new ValidationApiError(
          `Stock insuficiente no lote (disponível: ${estoqueAnterior})`,
        );
      }
      const estoqueFinal = estoqueAnterior - quantidade;

      await tx.estoqueMovimento.create({
        data: {
          produtoId,
          loteId,
          userId: sourceUserId,
          tipo: "SAIDA",
          quantidade,
          estoqueAnterior,
          estoqueFinal,
          origem: STOCK_TRANSFER_ORIGEM,
          documentoReferencia,
          observacoes: `Transferência para filial ${destBranch.name} (#${destBranch.id})`,
        },
      });

      await syncLoteStockBalanceCache(tx, { id: loteId });
      await syncStockBalanceCache(tx, produtoId);

      return {
        estoqueAnterior,
        estoqueFinal,
        numeroLote: lote.numeroLote as string,
        dataValidade: lote.dataValidade as Date,
        precoCompra: Number(lote.precoCompra),
        precoVenda: lote.precoVenda != null ? Number(lote.precoVenda) : null,
        fornecedorId: lote.fornecedorId as bigint | null,
        produto: lote.produto as {
          id: bigint;
          nomeComercial: string;
          barcode: string | null;
        },
      };
    });

    try {
      const destResult = await branchContext.run(
        {
          tenantId: data.tenantId,
          branchId: String(destBranch.id),
          dbName: destBranch.dbName,
          dbHost: destBranch.dbHost,
          dbPort: destBranch.dbPort,
          dbUsername: destBranch.dbUsername,
          dbPasswordCipherText: destBranch.dbPasswordCipherText,
          dbPasswordIv: destBranch.dbPasswordIv,
          dbPasswordTag: destBranch.dbPasswordTag,
        },
        async () => {
          const destPrisma = TenantPrismaFactory.getClient();
          const destUserId = await resolveDestUserId(
            destPrisma,
            sourceUser,
            data.centralUserId,
          );

          return destPrisma.$transaction(async (tx: any) => {
            let destProduto = sourceSnapshot.produto.barcode
              ? await tx.produto.findFirst({
                  where: {
                    barcode: sourceSnapshot.produto.barcode,
                    deletedAt: null,
                    ativo: true,
                  },
                })
              : null;

            if (!destProduto) {
              destProduto = await tx.produto.findFirst({
                where: {
                  nomeComercial: sourceSnapshot.produto.nomeComercial,
                  deletedAt: null,
                  ativo: true,
                },
              });
            }

            if (!destProduto) {
              throw new ValidationApiError(
                `Produto "${sourceSnapshot.produto.nomeComercial}" não existe na filial de destino. Cadastre o produto (mesmo código de barras) antes de transferir.`,
              );
            }

            const { start: dataValidadeInicio, end: dataValidadeFim } =
              getNormalizedExpiryRange(sourceSnapshot.dataValidade);

            await tx.$executeRaw`SELECT id FROM produtos WHERE id = ${destProduto.id} FOR UPDATE`;
            await tx.$executeRaw`SELECT id FROM lotes WHERE produtoId = ${destProduto.id} AND deletedAt IS NULL FOR UPDATE`;

            let destLote = await tx.lote.findFirst({
              where: {
                produtoId: destProduto.id,
                numeroLote: sourceSnapshot.numeroLote,
                dataValidade: {
                  gte: dataValidadeInicio,
                  lt: dataValidadeFim,
                },
                deletedAt: null,
              },
              orderBy: { id: "asc" },
            });

            const estoqueAnterior = destLote
              ? await getLoteQuantidadeFromMovements(tx, destLote.id)
              : 0;

            if (destLote) {
              destLote = await tx.lote.update({
                where: { id: destLote.id },
                data: {
                  quantidadeInicial: { increment: quantidade },
                  precoCompra: sourceSnapshot.precoCompra,
                  precoVenda:
                    sourceSnapshot.precoVenda ?? destLote.precoVenda,
                  ativo: true,
                  fornecedorId:
                    destLote.fornecedorId ?? sourceSnapshot.fornecedorId,
                },
              });
            } else {
              destLote = await tx.lote.create({
                data: {
                  produtoId: destProduto.id,
                  fornecedorId: sourceSnapshot.fornecedorId,
                  numeroLote: sourceSnapshot.numeroLote,
                  dataValidade: dataValidadeInicio,
                  quantidadeInicial: quantidade,
                  precoCompra: sourceSnapshot.precoCompra,
                  precoVenda: sourceSnapshot.precoVenda,
                  ativo: true,
                },
              });
            }

            const estoqueFinal = estoqueAnterior + quantidade;

            await tx.estoqueMovimento.create({
              data: {
                produtoId: destProduto.id,
                loteId: destLote.id,
                userId: destUserId,
                tipo: "ENTRADA",
                quantidade,
                estoqueAnterior,
                estoqueFinal,
                origem: STOCK_TRANSFER_ORIGEM,
                documentoReferencia,
                observacoes: `Transferência recebida da filial #${data.origemBranchId}`,
              },
            });

            await syncLoteStockBalanceCache(tx, { id: destLote.id });
            await syncStockBalanceCache(tx, destProduto.id);

            return {
              produtoId: destProduto.id.toString(),
              loteId: destLote.id.toString(),
              estoqueAnterior,
              estoqueFinal,
            };
          });
        },
      );

      return {
        message: "Transferência entre filiais registada com sucesso",
        documentoReferencia,
        origem: {
          branchId: data.origemBranchId,
          tipo: "SAIDA",
          origemMovimento: STOCK_TRANSFER_ORIGEM,
          estoqueAnterior: sourceSnapshot.estoqueAnterior,
          estoqueFinal: sourceSnapshot.estoqueFinal,
        },
        destino: {
          branchId: String(destBranch.id),
          branchName: destBranch.name,
          tipo: "ENTRADA",
          origemMovimento: STOCK_TRANSFER_ORIGEM,
          ...destResult,
        },
      };
    } catch (error) {
      // Compensa SAIDA na origem se a ENTRADA no destino falhar.
      await sourcePrisma.$transaction(async (tx: any) => {
        await tx.$executeRaw`SELECT id FROM lotes WHERE id = ${loteId} FOR UPDATE`;
        const estoqueAnterior = await getLoteQuantidadeFromMovements(tx, loteId);
        const estoqueFinal = estoqueAnterior + quantidade;
        await tx.estoqueMovimento.create({
          data: {
            produtoId,
            loteId,
            userId: sourceUserId,
            tipo: "ENTRADA",
            quantidade,
            estoqueAnterior,
            estoqueFinal,
            origem: STOCK_TRANSFER_ORIGEM,
            documentoReferencia,
            observacoes: `Estorno automático de transferência falhada (${documentoReferencia})`,
          },
        });
        await syncLoteStockBalanceCache(tx, { id: loteId });
        await syncStockBalanceCache(tx, produtoId);
      });
      throw error;
    }
  }
}

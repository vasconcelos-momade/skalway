import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import {
  NotFoundApiError,
  ValidationApiError,
} from "../../../../../../shared/http/api-error";
import { ComplianceAuditService } from "../../../../../../shared/services/compliance-audit.service";
import { mapLoteListItem } from "./lote.mapper";

export interface UpdateLoteDTO {
  loteId: string;
  numeroLote?: string;
  dataValidade?: string;
  dataFabricacao?: string | null;
  fornecedorId?: string | null;
  userId: string;
}

function parseDate(value?: string | null): Date | null | undefined {
  if (value === undefined) return undefined;
  if (value == null || value.trim() === "") return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new ValidationApiError("Data inválida");
  }
  return parsed;
}

export class UpdateLoteUseCase {
  async execute(data: UpdateLoteDTO) {
    const prisma = getPrisma() as any;

    return prisma.$transaction(async (tx: any) => {
      const loteId = BigInt(data.loteId);
      await tx.$executeRaw`SELECT id FROM lotes WHERE id = ${loteId} FOR UPDATE`;

      const lote = await tx.lote.findFirst({
        where: { id: loteId, deletedAt: null, ativo: true },
        select: {
          id: true,
          produtoId: true,
          fornecedorId: true,
          numeroLote: true,
          dataValidade: true,
          dataFabricacao: true,
          precoCompra: true,
          produto: { select: { id: true, nomeComercial: true, barcode: true } },
          fornecedor: { select: { id: true, nome: true } },
        },
      });

      if (!lote) {
        throw new NotFoundApiError(`Lote ${data.loteId} não encontrado`);
      }

      const updateData: Record<string, unknown> = {
        version: { increment: 1 },
      };

      if (data.numeroLote !== undefined) {
        const numeroLote = data.numeroLote.trim();
        if (numeroLote.length < 1) {
          throw new ValidationApiError("Número do lote é obrigatório");
        }
        updateData.numeroLote = numeroLote;
      }

      const dataValidade = parseDate(data.dataValidade);
      if (dataValidade !== undefined) {
        if (dataValidade == null) {
          throw new ValidationApiError("Data de validade é obrigatória");
        }
        updateData.dataValidade = dataValidade;
      }

      const dataFabricacao = parseDate(data.dataFabricacao);
      if (dataFabricacao !== undefined) {
        updateData.dataFabricacao = dataFabricacao;
      }

      if (data.fornecedorId !== undefined) {
        const fornecedorIdRaw = data.fornecedorId?.trim() || null;
        if (fornecedorIdRaw == null) {
          updateData.fornecedorId = null;
        } else {
          const fornecedorId = BigInt(fornecedorIdRaw);
          const fornecedor = await tx.fornecedor.findFirst({
            where: { id: fornecedorId, deletedAt: null, ativo: true },
            select: { id: true },
          });
          if (!fornecedor) {
            throw new NotFoundApiError("Fornecedor não encontrado");
          }

          const produtoFornecedor = await tx.produtoFornecedor.findUnique({
            where: {
              produtoId_fornecedorId: {
                produtoId: lote.produtoId,
                fornecedorId,
              },
            },
          });

          if (!produtoFornecedor) {
            await tx.produtoFornecedor.create({
              data: {
                produtoId: lote.produtoId,
                fornecedorId,
                precoCompra: Number(lote.precoCompra ?? 0),
              },
            });
          }

          updateData.fornecedorId = fornecedorId;
        }
      }

      const updated = await tx.lote.update({
        where: { id: loteId },
        data: updateData,
        include: {
          produto: { select: { id: true, nomeComercial: true, barcode: true } },
          fornecedor: { select: { id: true, nome: true } },
        },
      });

      const complianceService = new ComplianceAuditService();
      await complianceService.createImmutableLog(
        {
          userId: data.userId,
          action: "LOTE_UPDATE",
          entity: "Lote",
          entityId: data.loteId,
          before: {
            numeroLote: lote.numeroLote,
            dataValidade: lote.dataValidade?.toISOString?.() ?? lote.dataValidade,
            dataFabricacao:
              lote.dataFabricacao?.toISOString?.() ?? lote.dataFabricacao,
            fornecedorId: lote.fornecedorId?.toString?.() ?? null,
          },
          after: {
            numeroLote: updated.numeroLote,
            dataValidade:
              updated.dataValidade?.toISOString?.() ?? updated.dataValidade,
            dataFabricacao:
              updated.dataFabricacao?.toISOString?.() ??
              updated.dataFabricacao,
            fornecedorId: updated.fornecedorId?.toString?.() ?? null,
          },
        },
        tx,
      );

      return {
        message: "Lote actualizado com sucesso",
        lote: mapLoteListItem(updated),
      };
    });
  }
}

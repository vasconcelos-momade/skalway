import { randomUUID } from "node:crypto";
import { getPrisma } from "../../../../../infrastructure/prisma/tenant-prisma.factory";
import { ComplianceAuditService } from "../../../../../shared/services/compliance-audit.service";
import type {
  CashflowOperationBody,
  CashflowOrigem,
} from "../dto/cashflow.dto";

/** Operações manuais de tesouraria (não incluem VENDA — essa vem do POS). */
export type CashflowOperationKind =
  | "DESPESA_OPERACIONAL"
  | "COMPRA_ESTOQUE"
  | "SUPRIMENTO"
  | "SANGRIA"
  | "ESTORNO";

type RegisterCashflowOperationInput = CashflowOperationBody & {
  userId: string;
  kind: CashflowOperationKind;
};

function round2(value: number) {
  return Math.round(value * 100) / 100;
}

/**
 * Ledger financeiro (DRE) separado do saldo físico:
 * - DESPESA_OPERACIONAL → EXPENSE (impacta Lucro Líquido)
 * - COMPRA_ESTOQUE → PURCHASE (não impacta Lucro; custo via CMV na venda)
 * - SANGRIA → ADJUSTMENT (sai do caixa, NÃO é despesa)
 * - SUPRIMENTO → ADJUSTMENT (entra no caixa, NÃO é receita)
 * - ESTORNO → ADJUSTMENT (ajusta saldo, NÃO é receita)
 */
function resolveFinancialMovementType(
  kind: CashflowOperationKind,
): "EXPENSE" | "PURCHASE" | "ADJUSTMENT" {
  if (kind === "DESPESA_OPERACIONAL") return "EXPENSE";
  if (kind === "COMPRA_ESTOQUE") return "PURCHASE";
  return "ADJUSTMENT";
}

/** SUPRIMENTO/ESTORNO (correção) entram; DESPESA_OPERACIONAL/COMPRA_ESTOQUE/SANGRIA saem. */
function resolveDirection(kind: CashflowOperationKind): "increment" | "decrement" {
  return kind === "SUPRIMENTO" || kind === "ESTORNO" ? "increment" : "decrement";
}

function defaultOrigem(
  kind: CashflowOperationKind,
  origem?: CashflowOrigem | null,
): CashflowOrigem {
  if (origem) return origem;
  switch (kind) {
    case "SUPRIMENTO":
      return "SUPRIMENTO";
    case "SANGRIA":
      return "SANGRIA";
    case "DESPESA_OPERACIONAL":
      return "DESPESA_OPERACIONAL";
    case "COMPRA_ESTOQUE":
      return "COMPRA_ESTOQUE";
    case "ESTORNO":
      return "ESTORNO";
  }
}

function allowsCategoria(kind: CashflowOperationKind): boolean {
  return kind === "DESPESA_OPERACIONAL" || kind === "COMPRA_ESTOQUE";
}

export class RegisterCashflowOperationUseCase {
  async execute(input: RegisterCashflowOperationInput) {
    const prisma = getPrisma();
    const valor = round2(Number(input.valor));

    if (!Number.isFinite(valor) || valor <= 0) {
      throw new Error("Valor inválido");
    }

    const sessao = await prisma.caixaSessao.findFirst({
      where: {
        userId: BigInt(input.userId),
        status: "ABERTA",
        deletedAt: null,
      },
      orderBy: { openedAt: "desc" },
    });

    if (!sessao) {
      throw new Error(
        "Não existe sessão de caixa aberta. Abra o caixa no POS antes de registar movimentos.",
      );
    }

    const origem = defaultOrigem(input.kind, input.origem);
    const direction = resolveDirection(input.kind);
    const idempotencyKey =
      input.idempotencyKey?.trim() ||
      `CASHFLOW-${input.kind}-${sessao.caixaId}-${Date.now()}-${randomUUID()}`;

    return prisma.$transaction(async (tx) => {
      const caixas: Array<{ id: bigint; saldoAtual: unknown; saldo_atual?: unknown }> =
        await tx.$queryRaw`SELECT * FROM caixas WHERE id = ${sessao.caixaId} FOR UPDATE`;
      const caixa = caixas[0];

      if (!caixa) {
        throw new Error("Caixa não encontrado");
      }

      const saldoAnterior = round2(
        Number(caixa.saldoAtual ?? caixa.saldo_atual ?? 0),
      );
      const saldoFinal =
        direction === "increment"
          ? round2(saldoAnterior + valor)
          : round2(saldoAnterior - valor);

      if (direction === "decrement" && saldoFinal < 0) {
        throw new Error("Saldo insuficiente para concluir a operação");
      }

      const descricao =
        input.descricao?.trim() ||
        `${input.kind} (${origem})`;

      const categoria = allowsCategoria(input.kind)
        ? input.kind === "COMPRA_ESTOQUE"
          ? (input.categoria ?? "COMPRA_STOCK")
          : (input.categoria ?? "OUTRO")
        : null;

      const movimento = await tx.caixaMovimento.create({
        data: {
          caixaId: sessao.caixaId,
          userId: BigInt(input.userId),
          tipo: input.kind,
          origem,
          categoria,
          valor,
          saldoAnterior,
          saldoFinal,
          idempotencyKey,
          descricao,
        },
      });

      await tx.caixa.update({
        where: { id: sessao.caixaId },
        data: {
          saldoAtual: saldoFinal,
          version: { increment: 1 },
        },
      });

      const financialType = resolveFinancialMovementType(input.kind);
      const financialMovement = await tx.financialMovement.create({
        data: {
          userId: BigInt(input.userId),
          caixaId: sessao.caixaId,
          type: financialType,
          amount: valor,
          reference: descricao,
          idempotencyKey: `FIN-${idempotencyKey}`,
        },
      });

      await tx.cashBalance.upsert({
        where: { caixaId: sessao.caixaId },
        update: {
          saldoTotal:
            direction === "increment"
              ? { increment: valor }
              : { decrement: valor },
          saldoDinheiro:
            direction === "increment"
              ? { increment: valor }
              : { decrement: valor },
        },
        create: {
          caixaId: sessao.caixaId,
          saldoTotal: direction === "increment" ? valor : 0,
          saldoDinheiro: direction === "increment" ? valor : 0,
          saldoDigital: 0,
        },
      });

      const audit = new ComplianceAuditService();
      await audit.createImmutableLog(
        {
          userId: input.userId,
          action: `CASHFLOW_${input.kind}`,
          entity: "CaixaMovimento",
          entityId: movimento.id.toString(),
          after: {
            kind: input.kind,
            origem,
            valor,
            saldoAnterior,
            saldoFinal,
          },
        },
        tx,
      );

      return {
        movimentoId: movimento.id.toString(),
        financialMovementId: financialMovement.id.toString(),
        caixaId: sessao.caixaId.toString(),
        kind: input.kind,
        origem,
        valor,
        saldoAnterior,
        saldoAtual: saldoFinal,
        descricao,
      };
    });
  }
}

import {
  assertInvoiceAmounts,
  computeRemainingAmount,
  deriveInvoiceStatus,
} from "@skalway/billing";
import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import { writeCentralAuditLog } from "../../../infrastructure/central-audit.helper";
import { mapInvoiceFinancialFields } from "../services/invoice-response.mapper";

export interface ApplyInvoiceDiscountDTO {
  tenantId: string;
  invoiceId: string;
  discount: number;
  reason?: string | null;
  userId?: string | null;
}

const DISCOUNTABLE_STATUSES = new Set(["pendente", "parcial", "vencido"]);

/**
 * Aplica desconto comercial absoluto (MZN) a uma fatura.
 * Recalcula remainingAmount e status; regras ficam no backend.
 */
export class ApplyInvoiceDiscountUseCase {
  async execute(data: ApplyInvoiceDiscountDTO) {
    if (!Number.isFinite(data.discount) || data.discount < 0) {
      throw new Error("discount deve ser um valor ≥ 0.");
    }

    return runWithCentralTenant(data.tenantId, async () => {
      const prisma = prismaCentralUnscoped as any;
      const tenantId = BigInt(data.tenantId);
      const invoiceId = BigInt(data.invoiceId);
      const userId = data.userId ? BigInt(data.userId) : null;
      const discount =
        Math.round(Number(data.discount) * 100) / 100;

      return prisma.$transaction(async (tx: any) => {
        const invoice = await tx.invoice.findFirst({
          where: {
            id: invoiceId,
            tenantId,
            deletedAt: null,
          },
        });

        if (!invoice) {
          throw new Error("Fatura não encontrada.");
        }

        const status = String(invoice.status);
        if (!DISCOUNTABLE_STATUSES.has(status)) {
          throw new Error(
            `Não é possível aplicar desconto a fatura com estado "${status}".`,
          );
        }

        const amount = Number(invoice.amount);
        const paidAmount = Number(invoice.paidAmount ?? 0);
        const previousDiscount = Number(invoice.discount ?? 0);

        assertInvoiceAmounts(amount, paidAmount, discount);
        const remainingAmount = computeRemainingAmount(
          amount,
          paidAmount,
          discount,
        );
        const nextStatus = deriveInvoiceStatus(
          amount,
          paidAmount,
          status,
          discount,
        );

        // Invoice não tem updatedBy — auditoria fica no audit log.
        const updated = await tx.invoice.update({
          where: { id: invoice.id },
          data: {
            discount,
            remainingAmount,
            status: nextStatus,
          },
        });

        await writeCentralAuditLog(
          {
            tenantId,
            userId,
            action: "INVOICE_DISCOUNT",
            entity: "Invoice",
            entityId: invoice.id.toString(),
            oldData: {
              discount: previousDiscount,
              remainingAmount: Number(invoice.remainingAmount),
              status,
            },
            newData: {
              discount,
              remainingAmount,
              status: nextStatus,
              reason: data.reason?.trim() || null,
            },
          },
          tx,
        );

        return {
          id: updated.id.toString(),
          number: updated.number,
          ...mapInvoiceFinancialFields(updated),
          status: updated.status,
          reason: data.reason?.trim() || null,
        };
      });
    });
  }
}

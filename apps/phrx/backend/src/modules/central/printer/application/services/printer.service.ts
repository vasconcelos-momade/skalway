import { serializePrinter } from "../../domain/printer.mapper";
import { DEFAULT_PRINTER_CONFIG } from "../../domain/default-printer.config";
import { writeCentralAuditLog } from "../../infrastructure/central-audit.helper";

export type CreateDefaultPrinterParams = {
  /** Cliente Prisma (tx da criação da Branch ou prisma unscoped). */
  tx: any;
  tenantId: bigint;
  branchId: bigint;
  userId?: bigint | null;
};

/**
 * Cria a impressora padrão da filial se ainda não existir nenhuma.
 * Deve correr na mesma transaction Prisma da criação da Branch.
 */
export class PrinterService {
  async createDefaultPrinter(params: CreateDefaultPrinterParams) {
    const { tx, tenantId, branchId, userId = null } = params;

    const existingCount = await tx.printer.count({
      where: {
        tenantId,
        branchId,
        deletedAt: null,
      },
    });

    if (existingCount > 0) {
      return null;
    }

    const cfg = DEFAULT_PRINTER_CONFIG;
    const printer = await tx.printer.create({
      data: {
        tenantId,
        branchId,
        deviceId: null,
        name: cfg.name,
        type: cfg.type,
        connection: cfg.connection,
        ip: cfg.ip,
        port: cfg.port,
        model: cfg.model,
        manufacturer: cfg.manufacturer,
        active: cfg.active,
      },
    });

    const serialized = serializePrinter(printer);
    await writeCentralAuditLog(
      {
        tenantId,
        branchId,
        userId,
        action: "CREATE",
        entity: "Printer",
        entityId: printer.id.toString(),
        newData: serialized,
      },
      tx,
    );

    return serialized;
  }
}

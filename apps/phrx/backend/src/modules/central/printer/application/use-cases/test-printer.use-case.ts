import { hostname } from "os";
import { PrintJobRepository } from "../../infrastructure/repositories/print-job.repository";
import { PrinterRepository } from "../../infrastructure/repositories/printer.repository";
import { writeCentralAuditLog } from "../../infrastructure/central-audit.helper";
import type { TestPrinterDTO } from "../dto/printer.dto";
import { ProcessPrintJobUseCase } from "./process-print-job.use-case";

/**
 * Cria um PrintJob de teste e processa-o de imediato (TCP ESC/POS / PDF).
 * Assim "Testar impressora" não depende do print-job.worker estar a correr.
 */
export class TestPrinterUseCase {
  constructor(
    private readonly printers = new PrinterRepository(),
    private readonly jobs = new PrintJobRepository(),
    private readonly processJob = new ProcessPrintJobUseCase(),
  ) {}

  async execute(input: {
    tenantId: string;
    printerId: string;
    userId?: string | null;
    data?: TestPrinterDTO;
  }) {
    const printer = await this.printers.findById(
      BigInt(input.printerId),
      BigInt(input.tenantId),
    );
    if (!printer) throw new Error("Impressora não encontrada");
    if (!printer.active) throw new Error("Impressora inactiva");

    const message =
      input.data?.message?.trim() ||
      `Teste Skalway Health — ${printer.name} — ${new Date().toISOString()}`;

    const job = await this.jobs.create(
      {
        tenantId: BigInt(input.tenantId),
        branchId: BigInt(printer.branchId),
        printerId: BigInt(input.printerId),
        document: "TEST",
        payload: {
          kind: "TEST",
          message,
          platform: input.data?.platform,
          printer: {
            id: printer.id,
            name: printer.name,
            type: printer.type,
            connection: printer.connection,
            ip: printer.ip,
            port: printer.port,
          },
          requestedAt: new Date().toISOString(),
        },
        maxAttempts: 2,
      },
      input.userId ? BigInt(input.userId) : null,
    );

    await writeCentralAuditLog({
      tenantId: BigInt(input.tenantId),
      branchId: BigInt(printer.branchId),
      userId: input.userId ? BigInt(input.userId) : null,
      action: "TEST",
      entity: "Printer",
      entityId: printer.id,
      data: { printJobId: job.id, message },
    });

    const workerId = `test-sync:${hostname()}`;
    const outcome = await this.processJob.execute({
      jobId: job.id,
      tenantId: input.tenantId,
      workerId,
    });

    const finalJob = outcome.job;
    const status = String(finalJob.status ?? "").toUpperCase();
    const printed = status === "PRINTED";
    const failed = status === "FAILED";

    let resultMessage = "Trabalho de teste processado";
    if (printed) {
      resultMessage = "Teste impresso com sucesso";
    } else if (failed) {
      const err =
        (finalJob as { errorMessage?: string | null }).errorMessage?.trim() ||
        "Falha ao contactar a impressora";
      resultMessage = `Falha no teste: ${err}`;
    }

    return {
      printer,
      job: finalJob,
      printed,
      failed,
      message: resultMessage,
    };
  }
}

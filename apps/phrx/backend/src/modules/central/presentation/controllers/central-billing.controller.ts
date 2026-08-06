import { z } from "zod";
import { GetTenantSubscriptionUseCase } from "../../billing/application/use-cases/get-tenant-subscription.use-case";
import { ListTenantInvoicesUseCase } from "../../billing/application/use-cases/list-tenant-invoices.use-case";
import { ListCentralInvoicesUseCase } from "../../billing/application/use-cases/list-central-invoices.use-case";
import { ListSubscriptionBranchHistoryUseCase } from "../../billing/application/use-cases/list-subscription-branch-history.use-case";
import { GetInvoiceUseCase } from "../../billing/application/use-cases/get-invoice.use-case";
import { ListTenantPaymentsUseCase } from "../../billing/application/use-cases/list-tenant-payments.use-case";
import { SubmitPaymentUseCase } from "../../billing/application/use-cases/submit-payment.use-case";
import { ConfirmPaymentUseCase } from "../../billing/application/use-cases/confirm-payment.use-case";
import { CreditWalletUseCase } from "../../billing/application/use-cases/credit-wallet.use-case";
import { GenerateMonthlyBillingService } from "../../billing/application/services/generate-monthly-billing.service";
import { generateCentralInvoicePdf } from "../../billing/application/services/generate-invoice-pdf.service";
import { ProcessSubscriptionLifecycleService } from "../../billing/application/services/process-subscription-lifecycle.service";
import { JobQueueService } from "../../../../infrastructure/queue/job-queue.service";
import { prismaCentralUnscoped } from "../../../../infrastructure/prisma/prisma-central.service";
import { serializeForJson } from "../../../../shared/http/serialize-json";
import { success } from "../../../../shared/http/api-response";
import { parseJsonBody, parseSearchParams } from "../../../../shared/http/request-validation";
import type { CentralAuthContext } from "../../../../shared/http/central-auth";
import { Role } from "../../../../infrastructure/prisma/central/generated/central";

const submitPaymentSchema = z
  .object({
    invoiceId: z.string().trim().min(1),
    amount: z.coerce.number().positive(),
    method: z.string().trim().min(1),
    reference: z.string().trim().optional().nullable(),
    proofUrl: z.string().trim().min(1).optional(),
    notes: z.string().trim().min(1).optional(),
  })
  .superRefine((value, ctx) => {
    const method = value.method.trim().toUpperCase();
    if (method !== "CASH" && !value.reference?.trim()) {
      ctx.addIssue({
        code: "custom",
        message: "Referência da transacção é obrigatória excepto para CASH.",
        path: ["reference"],
      });
    }
  });

const creditWalletSchema = z
  .object({
    amount: z.coerce.number().positive(),
    months: z.coerce.number().int().min(1).max(36),
    method: z.string().trim().min(1),
    reference: z.string().trim().optional().nullable(),
    notes: z.string().trim().min(1).optional().nullable(),
  })
  .superRefine((value, ctx) => {
    const method = value.method.trim().toUpperCase();
    if (method !== "CASH" && !value.reference?.trim()) {
      ctx.addIssue({
        code: "custom",
        message: "Referência da transacção é obrigatória excepto para CASH.",
        path: ["reference"],
      });
    }
  });

const lifecycleSchema = z.object({
  referenceDate: z.string().trim().min(1).optional(),
});

const generateMonthlySchema = z.object({
  referenceDate: z.string().trim().min(1).optional(),
  tenantId: z.string().trim().min(1).optional(),
  subscriptionId: z.string().trim().min(1).optional(),
  dueDays: z.coerce.number().int().positive().optional(),
  includeTrial: z.coerce.boolean().optional(),
  dryRun: z.coerce.boolean().optional(),
});

const listInvoicesQuerySchema = z.object({
  status: z.string().trim().min(1).optional(),
  limit: z.coerce.number().int().positive().optional(),
});

const listCentralInvoicesQuerySchema = z.object({
  status: z.string().trim().min(1).optional(),
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
});

const listCentralPaymentsQuerySchema = z.object({
  status: z.string().trim().min(1).optional(),
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
});

const listPaymentsQuerySchema = z.object({
  status: z.string().trim().min(1).optional(),
  invoiceId: z.string().trim().min(1).optional(),
  limit: z.coerce.number().int().positive().optional(),
});

const generateMonthlyQuerySchema = z.object({
  referenceDate: z.string().trim().min(1).optional(),
  tenantId: z.string().trim().min(1).optional(),
  subscriptionId: z.string().trim().min(1).optional(),
  dueDays: z.coerce.number().int().positive().optional(),
  includeTrial: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
  dryRun: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
  async: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .optional(),
});

export class CentralBillingController {
  async getSubscription(tenantId: string): Promise<Response> {
    const useCase = new GetTenantSubscriptionUseCase();
    const subscription = await useCase.execute({ tenantId });
    return Response.json(serializeForJson(subscription));
  }

  async listBranchHistory(tenantId: string, url: URL): Promise<Response> {
    const limitRaw = url.searchParams.get("limit");
    const limit = limitRaw ? Number(limitRaw) : undefined;
    const useCase = new ListSubscriptionBranchHistoryUseCase();
    const history = await useCase.execute({
      tenantId,
      limit: Number.isFinite(limit) ? limit : undefined,
    });
    return Response.json(serializeForJson(history));
  }

  async listInvoices(tenantId: string, url: URL): Promise<Response> {
    const { status, limit } = parseSearchParams(url, listInvoicesQuerySchema);

    const useCase = new ListTenantInvoicesUseCase();
    const invoices = await useCase.execute({ tenantId, status, limit });
    return Response.json(serializeForJson(invoices));
  }

  async listAllInvoices(auth: CentralAuthContext, url: URL): Promise<Response> {
    const query = parseSearchParams(url, listCentralInvoicesQuerySchema);
    const tenantIds =
      auth.role === Role.superadmin
        ? undefined
        : auth.payload.tenants.map((tenant) => tenant.id);

    const useCase = new ListCentralInvoicesUseCase();
    const result = await useCase.execute({
      ...query,
      tenantIds,
    });

    return success(result.items, 200, {
      page: result.page,
      pageSize: result.pageSize,
      hasMore: result.hasMore,
      totalCount: result.totalCount,
    });
  }

  async listAllPayments(auth: CentralAuthContext, url: URL): Promise<Response> {
    const query = parseSearchParams(url, listCentralPaymentsQuerySchema);
    const prisma = prismaCentralUnscoped as any;
    const page = Math.max(1, query.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, query.pageSize ?? 20));
    const search = query.q?.trim();

    const tenantFilter =
      auth.role === Role.superadmin
        ? undefined
        : {
            tenantId: {
              in: auth.payload.tenants.map((tenant) => BigInt(tenant.id)),
            },
          };

    const where = {
      deletedAt: null,
      ...tenantFilter,
      ...(query.status ? { status: query.status } : {}),
      ...(search
        ? {
            OR: [
              { reference: { contains: search } },
              { tenant: { name: { contains: search } } },
              { tenant: { companyName: { contains: search } } },
              { invoice: { number: { contains: search } } },
            ],
          }
        : {}),
    };

    const [totalCount, rows] = await prisma.$transaction([
      prisma.payment.count({ where }),
      prisma.payment.findMany({
        where,
        select: {
          id: true,
          tenantId: true,
          invoiceId: true,
          amount: true,
          method: true,
          status: true,
          reference: true,
          confirmedAt: true,
          createdAt: true,
          tenant: { select: { name: true, companyName: true } },
          invoice: { select: { number: true } },
        },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);

    const items = rows.slice(0, pageSize).map((payment: any) => ({
      id: payment.id.toString(),
      tenantId: payment.tenantId.toString(),
      tenantName: payment.tenant?.name ?? null,
      companyName: payment.tenant?.companyName ?? null,
      invoiceId: payment.invoiceId?.toString() ?? null,
      invoiceNumber: payment.invoice?.number ?? null,
      amount: Number(payment.amount),
      method: payment.method,
      status: payment.status,
      reference: payment.reference,
      confirmedAt: payment.confirmedAt,
      createdAt: payment.createdAt,
    }));

    return success(items, 200, {
      page,
      pageSize,
      hasMore: rows.length > pageSize,
      totalCount,
    });
  }

  async getInvoice(tenantId: string, invoiceId: string): Promise<Response> {
    const useCase = new GetInvoiceUseCase();
    const invoice = await useCase.execute({ tenantId, invoiceId });
    return Response.json(serializeForJson(invoice));
  }

  async getInvoicePdf(tenantId: string, invoiceId: string): Promise<Response> {
    const pdf = await generateCentralInvoicePdf(tenantId, invoiceId);
    return new Response(pdf, {
      status: 200,
      headers: {
        "content-type": "application/pdf",
        "content-disposition": `inline; filename="fatura-${invoiceId}.pdf"`,
      },
    });
  }

  async listPayments(tenantId: string, url: URL): Promise<Response> {
    const { status, invoiceId, limit } = parseSearchParams(url, listPaymentsQuerySchema);

    const useCase = new ListTenantPaymentsUseCase();
    const payments = await useCase.execute({ tenantId, status, invoiceId, limit });
    return Response.json(serializeForJson(payments));
  }

  async submitPayment(tenantId: string, req: Request, userId: string): Promise<Response> {
    const body = await parseJsonBody(req, submitPaymentSchema);

    const useCase = new SubmitPaymentUseCase();
    const payment = await useCase.execute({
      tenantId,
      invoiceId: body.invoiceId,
      amount: body.amount,
      method: body.method,
      reference: body.reference?.trim() || undefined,
      proofUrl: body.proofUrl,
      notes: body.notes,
      createdByUserId: userId,
    });

    return Response.json(serializeForJson(payment), { status: 201 });
  }

  async confirmPayment(
    tenantId: string,
    paymentId: string,
    userId: string,
  ): Promise<Response> {
    const useCase = new ConfirmPaymentUseCase();
    const result = await useCase.execute({
      tenantId,
      paymentId,
      confirmedByUserId: userId,
    });
    return Response.json(serializeForJson(result));
  }

  async creditWallet(
    tenantId: string,
    req: Request,
    userId: string,
  ): Promise<Response> {
    const body = await parseJsonBody(req, creditWalletSchema);
    const useCase = new CreditWalletUseCase();
    const result = await useCase.execute({
      tenantId,
      amount: body.amount,
      months: body.months,
      method: body.method,
      reference: body.reference?.trim() || undefined,
      notes: body.notes ?? null,
      userId,
    });
    return Response.json(serializeForJson(result), { status: 201 });
  }

  async processLifecycle(req: Request): Promise<Response> {
    const body = lifecycleSchema.parse(await this.parseOptionalJson(req));

    const service = new ProcessSubscriptionLifecycleService();
    const result = await service.execute({
      referenceDate:
        body.referenceDate != null
          ? String(body.referenceDate)
          : undefined,
    });

    return Response.json(serializeForJson(result));
  }

  async generateMonthly(req: Request, url: URL): Promise<Response> {
    const body = generateMonthlySchema.parse(await this.parseOptionalJson(req));
    const query = parseSearchParams(url, generateMonthlyQuerySchema);

    const payload = {
      referenceDate:
        body.referenceDate != null
          ? String(body.referenceDate)
          : query.referenceDate,
      tenantId:
        body.tenantId != null
          ? String(body.tenantId)
          : query.tenantId,
      subscriptionId:
        body.subscriptionId != null
          ? String(body.subscriptionId)
          : query.subscriptionId,
      dueDays:
        body.dueDays != null
          ? Number(body.dueDays)
          : query.dueDays,
      includeTrial: body.includeTrial === true || query.includeTrial === true,
      dryRun: body.dryRun === true || query.dryRun === true,
    };

    if (query.async === true) {
      const queue = new JobQueueService();
      const job = await queue.enqueue("billing.generate-monthly", payload);
      return Response.json(
        serializeForJson({
          status: "queued",
          jobId: job.id,
          type: job.type,
          queuedAt: job.createdAt,
        }),
        { status: 202 },
      );
    }

    const service = new GenerateMonthlyBillingService();
    const result = await service.execute(payload);
    return Response.json(serializeForJson(result));
  }

  private async parseOptionalJson(req: Request): Promise<Record<string, unknown>> {
    if (!req.headers.get("Content-Type")?.includes("application/json")) {
      return {};
    }
    try {
      const parsed = await req.json();
      return parsed && typeof parsed === "object" ? (parsed as Record<string, unknown>) : {};
    } catch {
      return {};
    }
  }
}

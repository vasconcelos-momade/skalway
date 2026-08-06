import { prismaCentralUnscoped } from "../../../../infrastructure/prisma/prisma-central.service";

export interface ListCentralAuditLogsDTO {
  page?: number;
  pageSize?: number;
  q?: string;
  entity?: string;
  action?: string;
  tenantId?: string;
  userId?: string;
}

export type CentralAuditLogItem = {
  id: string;
  action: string;
  entity: string;
  entityId: string | null;
  tenantId: string | null;
  tenantName: string | null;
  companyName: string | null;
  before: unknown;
  after: unknown;
  ip: string | null;
  path: string | null;
  method: string | null;
  createdAt: string;
  user: { id: string; nome: string; email: string | null } | null;
};

export type ListCentralAuditLogsResult = {
  items: CentralAuditLogItem[];
  page: number;
  pageSize: number;
  hasMore: boolean;
  totalCount: number;
};

/**
 * Lista append-only do AuditLog Central (superadmin / operadores).
 */
export class ListCentralAuditLogsUseCase {
  async execute(
    data: ListCentralAuditLogsDTO,
  ): Promise<ListCentralAuditLogsResult> {
    const prisma = prismaCentralUnscoped as any;
    const page = Math.max(1, data.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, data.pageSize ?? 20));
    const search = data.q?.trim();

    const where: Record<string, unknown> = {
      ...(data.tenantId ? { tenantId: BigInt(data.tenantId) } : {}),
      ...(data.userId ? { userId: BigInt(data.userId) } : {}),
      ...(data.entity ? { entity: data.entity } : {}),
      ...(data.action ? { action: data.action } : {}),
      ...(search
        ? {
            OR: [
              { action: { contains: search } },
              { entity: { contains: search } },
              { entityId: { contains: search } },
              { path: { contains: search } },
            ],
          }
        : {}),
    };

    const [totalCount, rows] = await prisma.$transaction([
      prisma.auditLog.count({ where }),
      prisma.auditLog.findMany({
        where,
        include: {
          user: { select: { id: true, name: true, email: true } },
          tenant: { select: { id: true, name: true, companyName: true } },
        },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);

    const items = rows.slice(0, pageSize).map((row: any): CentralAuditLogItem => ({
      id: row.id.toString(),
      action: row.action,
      entity: row.entity,
      entityId: row.entityId?.toString() ?? null,
      tenantId: row.tenantId?.toString() ?? null,
      tenantName: row.tenant?.name ?? null,
      companyName: row.tenant?.companyName ?? null,
      before: row.oldData ?? null,
      after: row.newData ?? null,
      ip: row.ip ?? null,
      path: row.path ?? null,
      method: row.method ?? null,
      createdAt: row.createdAt.toISOString(),
      user: row.user
        ? {
            id: row.user.id.toString(),
            nome: row.user.name,
            email: row.user.email ?? null,
          }
        : null,
    }));

    return {
      items,
      page,
      pageSize,
      hasMore: rows.length > pageSize,
      totalCount,
    };
  }
}

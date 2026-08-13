import { getPrisma } from "../../../../../infrastructure/prisma/tenant-prisma.factory";

type ServicoSearchFilters = {
  query?: string;
  includeInactive?: boolean;
  tipoServicoClinico?: string;
  page?: number;
  pageSize?: number;
};

type ServicoWritePayload = {
  nome?: string;
  tipoServicoClinico?: string;
  preco?: number;
  ativo?: boolean;
  taxRuleId?: bigint | null;
};

function serializeServico(row: any) {
  return {
    id: row.id.toString(),
    nome: row.nome,
    tipoServicoClinico: row.tipoServicoClinico,
    preco: Number(row.preco),
    ativo: Boolean(row.ativo),
    taxRuleId: row.taxRuleId?.toString() ?? null,
    taxRule: row.taxRule
      ? {
          id: row.taxRule.id.toString(),
          codigo: row.taxRule.codigo,
          nome: row.taxRule.nome,
        }
      : null,
    createdAt: row.createdAt?.toISOString?.() ?? row.createdAt,
    updatedAt: row.updatedAt?.toISOString?.() ?? row.updatedAt,
  };
}

export class ServicoRepository {
  private get prisma(): any {
    return getPrisma() as any;
  }

  async search(filters: ServicoSearchFilters = {}) {
    const query = filters.query?.trim() || undefined;
    const page = Math.max(1, filters.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, filters.pageSize ?? 20));

    const where = {
      ...(filters.includeInactive ? {} : { ativo: true }),
      ...(filters.tipoServicoClinico
        ? { tipoServicoClinico: filters.tipoServicoClinico }
        : {}),
      ...(query ? { nome: { contains: query } } : {}),
    };

    const [totalCount, rows] = await Promise.all([
      this.prisma.servico.count({ where }),
      this.prisma.servico.findMany({
        where,
        include: {
          taxRule: { select: { id: true, codigo: true, nome: true } },
        },
        orderBy: [{ nome: "asc" }, { id: "asc" }],
        skip: (page - 1) * pageSize,
        take: pageSize + 1,
      }),
    ]);

    return {
      items: rows.slice(0, pageSize).map(serializeServico),
      page,
      pageSize,
      hasMore: rows.length > pageSize,
      totalCount,
    };
  }

  async getStats() {
    const [total, activos, inactivos] = await Promise.all([
      this.prisma.servico.count(),
      this.prisma.servico.count({ where: { ativo: true } }),
      this.prisma.servico.count({ where: { ativo: false } }),
    ]);
    return {
      totalServicos: total,
      servicosActivos: activos,
      servicosInactivos: inactivos,
    };
  }

  async findById(id: bigint) {
    const row = await this.prisma.servico.findUnique({
      where: { id },
      include: {
        taxRule: { select: { id: true, codigo: true, nome: true } },
      },
    });
    return row ? serializeServico(row) : null;
  }

  async findByNome(nome: string) {
    return this.prisma.servico.findUnique({
      where: { nome },
      select: { id: true, nome: true },
    });
  }

  async countLinkedInvoiceItems(id: bigint) {
    return this.prisma.faturaItem.count({
      where: { servicoId: id },
    });
  }

  async create(data: ServicoWritePayload) {
    const row = await this.prisma.servico.create({
      data: {
        nome: data.nome!,
        tipoServicoClinico: data.tipoServicoClinico!,
        preco: data.preco!,
        ativo: data.ativo ?? true,
        taxRuleId: data.taxRuleId ?? null,
      },
      include: {
        taxRule: { select: { id: true, codigo: true, nome: true } },
      },
    });
    return serializeServico(row);
  }

  async update(id: bigint, data: ServicoWritePayload) {
    const row = await this.prisma.servico.update({
      where: { id },
      data: {
        ...(data.nome !== undefined ? { nome: data.nome } : {}),
        ...(data.tipoServicoClinico !== undefined
          ? { tipoServicoClinico: data.tipoServicoClinico }
          : {}),
        ...(data.preco !== undefined ? { preco: data.preco } : {}),
        ...(data.ativo !== undefined ? { ativo: data.ativo } : {}),
        ...(data.taxRuleId !== undefined ? { taxRuleId: data.taxRuleId } : {}),
      },
      include: {
        taxRule: { select: { id: true, codigo: true, nome: true } },
      },
    });
    return serializeServico(row);
  }

  async softDeactivate(id: bigint) {
    const row = await this.prisma.servico.update({
      where: { id },
      data: { ativo: false },
      include: {
        taxRule: { select: { id: true, codigo: true, nome: true } },
      },
    });
    return serializeServico(row);
  }
}

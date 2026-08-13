import { getPrisma } from "../../../../../infrastructure/prisma/tenant-prisma.factory";
import { POS_DEFAULT_PAGE_SIZE, POS_MAX_PAGE_SIZE } from "../../domain/pos-catalog.constants";

/** Where do catálogo POS — apenas serviços activos. */
export function buildPosServicosWhere(query?: string) {
  const trimmed = query?.trim();
  return {
    ativo: true as const,
    ...(trimmed ? { nome: { contains: trimmed } } : {}),
  };
}

export class SearchServicosUseCase {
  async execute(params?: {
    query?: string;
    page?: number;
    pageSize?: number;
  }) {
    const prisma = getPrisma();
    const page = Math.max(1, params?.page ?? 1);
    const pageSize = Math.min(
      POS_MAX_PAGE_SIZE,
      Math.max(1, params?.pageSize ?? POS_DEFAULT_PAGE_SIZE),
    );
    const where = buildPosServicosWhere(params?.query);

    const [totalCount, items] = await Promise.all([
      prisma.servico.count({ where }),
      prisma.servico.findMany({
        where,
        select: {
          id: true,
          nome: true,
          preco: true,
          tipoServicoClinico: true,
          ativo: true,
        },
        orderBy: [{ nome: "asc" }, { id: "asc" }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    return {
      items,
      page,
      pageSize,
      totalCount,
      hasMore: page * pageSize < totalCount,
    };
  }
}

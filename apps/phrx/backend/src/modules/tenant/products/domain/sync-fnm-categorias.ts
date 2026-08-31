import { FNM_CATEGORIAS } from "./fnm-categorias";

type PrismaLike = {
  categoria: {
    findFirst: (args: unknown) => Promise<{
      id: bigint;
      nome: string;
      codigoFNM: string | null;
      descricao: string | null;
      ativo: boolean;
      deletedAt: Date | null;
    } | null>;
    create: (args: unknown) => Promise<unknown>;
    update: (args: unknown) => Promise<unknown>;
    findMany: (args: unknown) => Promise<
      Array<{
        id: bigint;
        codigoFNM: string | null;
        _count?: { produtos: number };
      }>
    >;
  };
};

export async function syncFnmCategorias(prisma: PrismaLike) {
  for (const item of FNM_CATEGORIAS) {
    const existing = await prisma.categoria.findFirst({
      where: {
        OR: [{ codigoFNM: item.codigoFNM }, { nome: item.nome }],
      },
      orderBy: [{ id: "asc" }],
    });

    if (!existing) {
      await prisma.categoria.create({
        data: {
          nome: item.nome,
          codigoFNM: item.codigoFNM,
          descricao: "Categoria terapêutica FNM (Nível 1)",
          ativo: true,
        },
      });
      continue;
    }

    const data: Record<string, unknown> = {};
    if (existing.nome !== item.nome) data.nome = item.nome;
    if (existing.codigoFNM !== item.codigoFNM) data.codigoFNM = item.codigoFNM;
    if (!existing.descricao) {
      data.descricao = "Categoria terapêutica FNM (Nível 1)";
    }
    if (existing.ativo !== true) data.ativo = true;
    if (existing.deletedAt != null) data.deletedAt = null;

    if (Object.keys(data).length > 0) {
      await prisma.categoria.update({
        where: { id: existing.id },
        data,
      });
    }
  }

  const validCodigos = FNM_CATEGORIAS.map((item) => item.codigoFNM);
  const obsolete = await prisma.categoria.findMany({
    where: {
      codigoFNM: { notIn: validCodigos },
      deletedAt: null,
    },
    include: {
      _count: {
        select: {
          produtos: {
            where: { deletedAt: null },
          },
        },
      },
    },
  });

  for (const categoria of obsolete) {
    if ((categoria._count?.produtos ?? 0) === 0) {
      await prisma.categoria.update({
        where: { id: categoria.id },
        data: { ativo: false },
      });
    }
  }
}

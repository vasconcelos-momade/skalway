import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";
import type { OpenInventoryDTO } from "../../dto/inventory.dto";
import { generateInventarioCodigo } from "./inventory-code.service";
import { mapInventarioDetalhe } from "./inventory.mapper";

export class OpenInventoryUseCase {
  async execute(data: OpenInventoryDTO & { userId: string }) {
    const prisma = getPrisma();

    return prisma.$transaction(async (tx: any) => {
      const aberto = await tx.inventario.findFirst({
        where: { status: { in: ["ABERTO", "EM_CONTAGEM"] } },
        select: { id: true, codigo: true, status: true },
      });

      if (aberto) {
        throw new Error(
          `Já existe um inventário aberto (${aberto.codigo}). Conclua ou cancele antes de iniciar outro.`,
        );
      }

      const codigo = await generateInventarioCodigo(tx);

      const inventario = await tx.inventario.create({
        data: {
          codigo,
          observacao: data.observacao?.trim() || null,
          status: "ABERTO",
          iniciadoPorId: BigInt(data.userId),
        },
        include: {
          iniciadoPor: { select: { id: true, name: true } },
          itens: true,
        },
      });

      return mapInventarioDetalhe(inventario);
    });
  }
}

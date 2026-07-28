import { getPrisma } from "../../../../../../infrastructure/prisma/tenant-prisma.factory";

export class DeleteInventoryItemUseCase {
  async execute(inventarioId: string, itemId: string) {
    const prisma = getPrisma();

    return prisma.$transaction(async (tx: any) => {
      const invId = BigInt(inventarioId);
      const itId = BigInt(itemId);

      await tx.$executeRaw`SELECT id FROM inventarios WHERE id = ${invId} FOR UPDATE`;

      const inventario = await tx.inventario.findUnique({ where: { id: invId } });
      if (!inventario) {
        throw new Error("Inventário não encontrado");
      }

      if (inventario.status !== "EM_CONTAGEM" && inventario.status !== "ABERTO") {
        throw new Error("Só é possível remover itens de inventários abertos ou em contagem");
      }

      const item = await tx.inventarioItem.findFirst({
        where: { id: itId, inventarioId: invId },
      });

      if (!item) {
        throw new Error("Item de inventário não encontrado");
      }

      await tx.inventarioItem.delete({ where: { id: itId } });

      return { success: true, id: itemId };
    });
  }
}

import { prismaCentral } from "./infrastructure/prisma/prisma-central.service";
import { CreateTenantUseCase } from "./modules/central/tenants/application/use-cases/create-tenant.use-case";
import bcrypt from "bcryptjs";

async function test() {
  console.log("🧪 Iniciando Teste de Registro de Tenant...");

  try {
    // 1. Garantir que temos um usuário dono no Central
    const email = "admin@skalway.com";
    let user = await prismaCentral.user.findFirst({
      where: { email, deletedAt: null },
    });

    if (!user) {
      console.log("👤 Criando usuário administrador global...");
      const hashedPassword = await bcrypt.hash("admin123", 10);
      user = await prismaCentral.user.create({
        data: {
          name: "Admin Global",
          email: email,
          password: hashedPassword,
          role: "superadmin",
        },
      });
    }

    // 2. Instanciar o Use Case
    const createTenant = new CreateTenantUseCase();

    // 3. Tentar criar um novo tenant
    const result = await createTenant.execute({
      tenantName: "Farmácia Central de Maputo",
      userId: user.id.toString(),
      email: "farmacia.maputo@example.com",
      branches: [
        { name: "Farmácia Central de Maputo" },
        { name: "Filial Nampula" },
      ],
    });

    console.log("✅ Resultado do Registro:", result);
    console.log("🚀 Teste finalizado com sucesso!");
  } catch (error) {
    console.error("❌ Falha no teste:", error);
  } finally {
    await prismaCentral.$disconnect();
  }
}

test();

import { PrismaClient } from "../src/infrastructure/prisma/central/generated/central";
import bcrypt from "bcryptjs";
import process from "node:process";

const prisma = new PrismaClient();

const SUPER_ADMIN_EMAIL = "admin@skalway.com";
const SUPER_ADMIN_PASSWORD = "admin123";

const PLANS = [
  {
    slug: "starter",
    name: "Starter",
    monthlyPrice: 1990.0,
    includedBranches: 1,
    extraBranchPrice: 900.0,
    isEnterprise: false,
    billingIntervalMonths: 1,
    trialDays: 30,
  },
  {
    slug: "enterprise",
    name: "Enterprise",
    monthlyPrice: 0.0,
    includedBranches: 1,
    extraBranchPrice: 0.0,
    isEnterprise: true,
    billingIntervalMonths: 1,
    trialDays: 30,
  },
] as const;

async function seedSuperAdmin() {
  console.log("👤 [central] SUPER_ADMIN...");
  const existing = await prisma.user.findFirst({
    where: { email: SUPER_ADMIN_EMAIL, deletedAt: null },
  });

  if (existing) {
    console.log(`   ⏭  SUPER_ADMIN já existe (${SUPER_ADMIN_EMAIL}) — a saltar.`);
    return;
  }

  const hashedPassword = await bcrypt.hash(SUPER_ADMIN_PASSWORD, 10);
  await prisma.user.create({
    data: {
      name: "Admin SkalWay",
      email: SUPER_ADMIN_EMAIL,
      password: hashedPassword,
      role: "superadmin",
    },
  });
  console.log(`   ✅ SUPER_ADMIN criado (${SUPER_ADMIN_EMAIL}).`);
}

async function seedPlans() {
  console.log("📦 [central] Planos...");

  for (const plan of PLANS) {
    await prisma.plan.upsert({
      where: { slug: plan.slug },
      update: {
        name: plan.name,
        monthlyPrice: plan.monthlyPrice,
        includedBranches: plan.includedBranches,
        extraBranchPrice: plan.extraBranchPrice,
        isEnterprise: plan.isEnterprise,
        billingIntervalMonths: plan.billingIntervalMonths,
        trialDays: plan.trialDays,
        active: true,
        deletedAt: null,
      },
      create: {
        slug: plan.slug,
        name: plan.name,
        monthlyPrice: plan.monthlyPrice,
        includedBranches: plan.includedBranches,
        extraBranchPrice: plan.extraBranchPrice,
        isEnterprise: plan.isEnterprise,
        billingIntervalMonths: plan.billingIntervalMonths,
        trialDays: plan.trialDays,
        active: true,
      },
    });
  }

  const catalogSlugs = PLANS.map((p) => p.slug);
  const starter = await prisma.plan.findUnique({ where: { slug: "starter" } });
  if (starter) {
    const obsolete = await prisma.plan.findMany({
      where: { slug: { notIn: [...catalogSlugs] }, deletedAt: null },
    });
    for (const plan of obsolete) {
      await prisma.subscription.updateMany({
        where: { planId: plan.id, deletedAt: null },
        data: { planId: starter.id },
      });
      await prisma.plan.update({
        where: { id: plan.id },
        data: { active: false },
      });
    }
  }

  console.log(`   ✅ Planos activos: ${catalogSlugs.join(", ")}.`);
}

async function seedPermissions() {
  console.log("🔑 [central] Permissões base...");

  const permissions = [
    { code: "TENANT_VIEW", name: "Ver dados da empresa" },
    { code: "TENANT_EDIT", name: "Editar dados da empresa" },
    { code: "BRANCH_VIEW", name: "Ver filiais" },
    { code: "BRANCH_CREATE", name: "Criar filiais" },
    { code: "BRANCH_EDIT", name: "Editar filiais" },
    { code: "USER_VIEW", name: "Ver utilizadores" },
    { code: "USER_CREATE", name: "Criar utilizadores" },
    { code: "USER_EDIT", name: "Editar utilizadores" },
    { code: "USER_DELETE", name: "Remover utilizadores" },
    { code: "PRODUCT_VIEW", name: "Ver catálogo de produtos" },
    { code: "PRODUCT_CREATE", name: "Cadastrar produtos" },
    { code: "PRODUCT_EDIT", name: "Editar produtos" },
    { code: "STOCK_VIEW", name: "Ver níveis de stock" },
    { code: "SALE_CREATE", name: "Realizar vendas" },
    { code: "SALE_VIEW", name: "Ver histórico de vendas" },
    { code: "FINANCE_VIEW", name: "Ver relatórios financeiros" },
  ];

  for (const p of permissions) {
    await prisma.permission.upsert({
      where: { code: p.code },
      update: { name: p.name },
      create: p,
    });
  }

  console.log(`   ✅ ${permissions.length} permissões upserted.`);
}

async function seedCentralSettings() {
  console.log("🏢 [central] Configurações institucionais...");
  const existing = await (prisma as any).centralSettings.findFirst({
    where: { singletonKey: 1, deletedAt: null },
  });
  if (existing) {
    console.log("   ⏭  CentralSettings já existe — a saltar.");
    return;
  }

  await (prisma as any).centralSettings.create({
    data: {
      singletonKey: 1,
      companyName: "Skalway Technologies, Lda.",
      companyNuit: "400000000",
      companyEmail: "contacto@skalway.com",
      companyPhone: "+258 84 000 0000",
      companyAddress: "Maputo, Moçambique",
      companyCity: "Maputo",
      companyProvince: "Maputo",
      companyCountry: "MZ",
      mpesaAccountName: "Skalway Technologies, Lda.",
      mpesaAccountNumber: "+258 84 000 0000",
      emolaAccountName: "Skalway Technologies, Lda.",
      emolaAccountNumber: "+258 86 000 0000",
      bankName: "Millennium BIM",
      bankAccountName: "Skalway Technologies, Lda.",
      bankAccountNumber: "123456789",
      bankAccountNib: "00000000000000000000000",
      bankAccountSwift: "BIMOMZMXXXX",
      bankTransferInstructions:
        "Indique o número da factura na descrição da transferência.",
      invoiceFooter: "Obrigado pela confiança na Skalway Technologies.",
      receiptFooter: "Comprovativo emitido pela Central PhRx.",
      defaultMessage: "Documento oficial emitido pela Central PhRx.",
      active: true,
    },
  });
  console.log("   ✅ CentralSettings criada (Skalway Technologies).");
}

async function main() {
  console.log("🚀 [central] Iniciando seeders (idempotente)...");
  await seedSuperAdmin();
  await seedPlans();
  await seedPermissions();
  await seedCentralSettings();
  console.log("🎉 [central] Seeders concluídos.");
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

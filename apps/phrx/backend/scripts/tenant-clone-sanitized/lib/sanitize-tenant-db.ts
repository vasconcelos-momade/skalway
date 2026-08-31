import { PrismaClient as PrismaTenantClient } from "../../../src/infrastructure/prisma/tenant/generated/tenant";
import {
  DEFAULT_CLIENTE_NOME,
  DEFAULT_CLIENTE_NAMES,
} from "../../../src/modules/tenant/clients/domain/default-cliente";
import { loadMysqlCliConfig } from "./mysql-cli";
import { assertNotProductionTarget } from "./protected-databases";

export type SanitizeSummary = {
  auditLogsRemoved: number;
  businessEventsRemoved: number;
  digitalSignaturesRemoved: number;
  sanitarioReportsRemoved: number;
  reportSnapshotsRemoved: number;
  usersAnonymized: number;
  clientesAnonymized: number;
  empresasAnonymized: number;
  receitasAnonymized: number;
  fornecedoresAnonymized: number;
  faturasSnapshotsSanitized: number;
};

function buildTenantDbUrl(dbName: string): string {
  const config = loadMysqlCliConfig();
  return `mysql://root:${encodeURIComponent(config.rootPassword)}@${config.host}:${config.port}/${dbName}`;
}

function openTenantClient(dbName: string): PrismaTenantClient {
  assertNotProductionTarget(dbName, "sanitização tenant");
  return new PrismaTenantClient({
    datasources: { db: { url: buildTenantDbUrl(dbName) } },
  });
}

/**
 * Sanitização executada SOMENTE na base temporária.
 * Preserva integridade referencial — anonimiza em vez de apagar quando há FKs.
 */
export async function sanitizeTenantDatabase(
  dbName: string,
): Promise<SanitizeSummary> {
  const prisma = openTenantClient(dbName);

  const summary: SanitizeSummary = {
    auditLogsRemoved: 0,
    businessEventsRemoved: 0,
    digitalSignaturesRemoved: 0,
    sanitarioReportsRemoved: 0,
    reportSnapshotsRemoved: 0,
    usersAnonymized: 0,
    clientesAnonymized: 0,
    empresasAnonymized: 0,
    receitasAnonymized: 0,
    fornecedoresAnonymized: 0,
    faturasSnapshotsSanitized: 0,
  };

  try {
    // 1. Remover logs e auditoria sensível (sem dependências críticas de negócio)
    const audit = await prisma.auditLog.deleteMany({});
    summary.auditLogsRemoved = audit.count;

    const events = await prisma.businessEvent.deleteMany({});
    summary.businessEventsRemoved = events.count;

    const signatures = await prisma.digitalSignature.deleteMany({});
    summary.digitalSignaturesRemoved = signatures.count;

    const reports = await prisma.sanitarioReport.deleteMany({});
    summary.sanitarioReportsRemoved = reports.count;

    const snapshots = await prisma.reportSnapshot.deleteMany({});
    summary.reportSnapshotsRemoved = snapshots.count;

    // 2. Anonimizar utilizadores (manter IDs para FKs em faturas, movimentos, etc.)
    const users = await prisma.user.findMany({
      where: { deletedAt: null },
      select: { id: true },
    });

    for (const user of users) {
      const id = user.id.toString();
      await prisma.user.update({
        where: { id: user.id },
        data: {
          name: `Utilizador Teste ${id}`,
          email: `user${id}@teste.local`,
          centralUserId: null,
        },
      });
      summary.usersAnonymized += 1;
    }

    // 3. Anonimizar clientes/pacientes (preservar Consumidor Final)
    const clientes = await prisma.cliente.findMany({
      where: {
        deletedAt: null,
        nome: { notIn: [...DEFAULT_CLIENTE_NAMES] },
      },
      select: { id: true },
    });

    for (const cliente of clientes) {
      const id = cliente.id.toString();
      await prisma.cliente.update({
        where: { id: cliente.id },
        data: {
          nome: `Cliente Teste ${id}`,
          telefone: null,
          email: `cliente${id}@teste.local`,
          documento: `DOC-${id.padStart(8, "0")}`,
          nuit: null,
          endereco: "Endereço anonimizado",
          dataNascimento: null,
          sexo: null,
        },
      });
      summary.clientesAnonymized += 1;
    }

    // Garantir Consumidor Final com nome canónico
    await prisma.cliente.updateMany({
      where: { nome: { in: [...DEFAULT_CLIENTE_NAMES] }, deletedAt: null },
      data: { nome: DEFAULT_CLIENTE_NOME, telefone: null, email: null, documento: null, nuit: null, endereco: null },
    });

    // 4. Anonimizar empresas/convenios
    const empresas = await prisma.empresa.findMany({
      where: { deletedAt: null },
      select: { id: true },
    });

    for (const empresa of empresas) {
      const id = empresa.id.toString();
      await prisma.empresa.update({
        where: { id: empresa.id },
        data: {
          nome: `Empresa Teste ${id}`,
          nuit: `NUIT-${id.padStart(8, "0")}`,
        },
      });
      summary.empresasAnonymized += 1;
    }

    // 5. Anonimizar receitas (dados médicos)
    const receitas = await prisma.receita.findMany({ select: { id: true } });
    for (const receita of receitas) {
      const id = receita.id.toString();
      await prisma.receita.update({
        where: { id: receita.id },
        data: {
          medicoNome: `Médico Teste ${id}`,
          numeroReceita: `REC-${id.padStart(8, "0")}`,
          unidadeSanitaria: "Unidade Teste",
          observacoes: null,
        },
      });
      summary.receitasAnonymized += 1;
    }

    // 6. Sanitizar contactos de fornecedores (manter nome comercial para lógica de compras)
    const fornecedores = await prisma.fornecedor.findMany({
      where: { deletedAt: null },
      select: { id: true, nome: true },
    });

    for (const fornecedor of fornecedores) {
      const id = fornecedor.id.toString();
      await prisma.fornecedor.update({
        where: { id: fornecedor.id },
        data: {
          email: `fornecedor${id}@teste.local`,
          telefone: `+258800${id.padStart(6, "0").slice(-6)}`,
          telefoneAlt: null,
          endereco: "Endereço anonimizado",
          contatoNome: `Contacto Teste ${id}`,
          nuit: fornecedor.nome ? `NUIT-F-${id.padStart(6, "0")}` : null,
        },
      });
      summary.fornecedoresAnonymized += 1;
    }

    // 7. Sanitizar snapshots fiscais com PII da filial
    const faturas = await prisma.fatura.updateMany({
      data: {
        branchEmail: "teste@farmacia.local",
        branchTelefone: "+258800000000",
        branchEndereco: "Endereço teste",
        branchNuit: "400000000",
      },
    });
    summary.faturasSnapshotsSanitized = faturas.count;

    // 8. Validar integridade referencial básica
    await validateReferentialIntegrity(prisma);

    return summary;
  } finally {
    await prisma.$disconnect().catch(() => undefined);
  }
}

async function validateReferentialIntegrity(
  prisma: PrismaTenantClient,
): Promise<void> {
  const orphanFaturaItems = await prisma.$queryRawUnsafe<
    Array<{ c: bigint | number }>
  >(
    `SELECT COUNT(*) AS c
     FROM fatura_itens fi
     LEFT JOIN faturas f ON f.id = fi.faturaId
     WHERE f.id IS NULL`,
  );

  const orphanCount = Number(orphanFaturaItems[0]?.c ?? 0);
  if (orphanCount > 0) {
    throw new Error(
      `Integridade referencial comprometida: ${orphanCount} fatura_itens órfãos.`,
    );
  }

  const essentialTables: Array<{ label: string; count: number }> = [
    { label: "produtos", count: await prisma.produto.count({ where: { deletedAt: null } }) },
    { label: "categorias", count: await prisma.categoria.count({ where: { deletedAt: null } }) },
    { label: "lotes", count: await prisma.lote.count({ where: { deletedAt: null } }) },
  ];

  for (const table of essentialTables) {
    if (table.count === 0) {
      console.warn(`⚠️  Tabela essencial "${table.label}" está vazia após sanitização.`);
    }
  }
}

export function formatSanitizeSummary(summary: SanitizeSummary): string {
  return [
    `  audit_logs removidos: ${summary.auditLogsRemoved}`,
    `  business_events removidos: ${summary.businessEventsRemoved}`,
    `  digital_signatures removidos: ${summary.digitalSignaturesRemoved}`,
    `  sanitario_reports removidos: ${summary.sanitarioReportsRemoved}`,
    `  report_snapshots removidos: ${summary.reportSnapshotsRemoved}`,
    `  users anonimizados: ${summary.usersAnonymized}`,
    `  clientes anonimizados: ${summary.clientesAnonymized}`,
    `  empresas anonimizadas: ${summary.empresasAnonymized}`,
    `  receitas anonimizadas: ${summary.receitasAnonymized}`,
    `  fornecedores sanitizados: ${summary.fornecedoresAnonymized}`,
    `  faturas (snapshots) sanitizadas: ${summary.faturasSnapshotsSanitized}`,
  ].join("\n");
}

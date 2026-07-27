import { getPrisma } from "../../../../../infrastructure/prisma/tenant-prisma.factory";
import { Prisma } from "../../../../../infrastructure/prisma/tenant/generated/tenant";
import { FinancialMetricsService } from "../../../finance/application/services/financial-metrics.service";

export interface ConsolidarFinanceiroDTO {
  dia?: number;
  mes: number;
  ano: number;
  periodo?: "DIARIO" | "MENSAL";
}

export class ConsolidarFinanceiroUseCase {
  async execute(data: ConsolidarFinanceiroDTO, externalTx?: Prisma.TransactionClient) {
    const prisma = getPrisma();
    const tx = externalTx || prisma;

    const periodo = data.periodo || (data.dia ? "DIARIO" : "MENSAL");

    let startDate: Date;
    let endDate: Date;

    if (periodo === "DIARIO" && data.dia) {
      startDate = new Date(data.ano, data.mes - 1, data.dia, 0, 0, 0);
      endDate = new Date(data.ano, data.mes - 1, data.dia, 23, 59, 59);
    } else {
      startDate = new Date(data.ano, data.mes - 1, 1, 0, 0, 0);
      endDate = new Date(data.ano, data.mes, 0, 23, 59, 59);
    }

    const metricsService = new FinancialMetricsService(prisma);
    const metrics = await metricsService.calculateDreMetrics(
      { from: startDate, to: endDate },
      tx,
    );

    const totalVendas = metrics.receita;
    const totalCustos = metrics.custos;
    const totalDespesas = metrics.despesas;
    const lucroBruto = metrics.lucroBruto;
    const lucroLiquido = metrics.lucroLiquido;
    const margemLucro = metrics.margemLucro;

    // 5. Atualizar ou Criar o Resumo (Upsert)
    const summary = await tx.financialSummary.upsert({
      where: {
        periodo_ano_mes_dia: {
          periodo: periodo,
          ano: data.ano,
          mes: data.mes,
          dia: data.dia ?? 0,
        },
      },
      update: {
        totalVendas,
        totalCustos,
        totalDespesas,
        lucroBruto,
        lucroLiquido,
        margemLucro,
      },
      create: {
        periodo: periodo,
        ano: data.ano,
        mes: data.mes,
        dia: data.dia ?? 0,
        totalVendas,
        totalCustos,
        totalDespesas,
        lucroBruto,
        lucroLiquido,
        margemLucro,
      },
    });

    return {
      success: true,
      periodo,
      summary,
    };
  }
}

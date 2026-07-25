export function buildMonthlyInvoiceDescription(params: {
  planName: string;
  planSlug: string;
  isEnterprise: boolean;
  branchesUsed: number;
  includedBranches: number;
  extraBranches: number;
  periodStart: Date;
  periodEnd: Date;
}): string {
  const periodLabel = `${params.periodStart.toISOString().slice(0, 10)} a ${params.periodEnd
    .toISOString()
    .slice(0, 10)}`;

  if (params.isEnterprise) {
    return `Faturacao mensal Enterprise (${params.planName}) para o periodo ${periodLabel}. Branches ativas: ${params.branchesUsed}.`;
  }

  return `Faturacao mensal do plano ${params.planName} (${params.planSlug}) para o periodo ${periodLabel}. Branches usadas: ${params.branchesUsed}. Incluidas: ${params.includedBranches}. Extras: ${params.extraBranches}.`;
}

export function buildTrialInvoiceDescription(params: {
  planName: string;
  planSlug: string;
  periodStart: Date;
  periodEnd: Date;
  branchesUsed: number;
  includedBranches: number;
  extraBranches: number;
}): string {
  const periodStart = params.periodStart.toISOString().slice(0, 10);
  const periodEnd = params.periodEnd.toISOString().slice(0, 10);

  return [
    `Conversao automatica do trial para o plano ${params.planName} (${params.planSlug}).`,
    `Periodo: ${periodStart} a ${periodEnd}.`,
    `Branches activas: ${params.branchesUsed}.`,
    `Incluidas: ${params.includedBranches}.`,
    `Extras: ${params.extraBranches}.`,
  ].join(" ");
}

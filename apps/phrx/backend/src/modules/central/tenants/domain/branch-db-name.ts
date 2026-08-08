/**
 * Naming imutável da base MySQL por filial.
 * Nunca usar tenantName, nome do proprietário ou outros dados mutáveis.
 *
 * Padrão: phrx_tenant_{tenantId}_branch_{branchId}
 */
export function buildBranchDbName(
  tenantId: string | number | bigint,
  branchId: string | number | bigint,
): string {
  const tid = String(tenantId).trim();
  const bid = String(branchId).trim();
  if (!/^\d+$/.test(tid) || !/^\d+$/.test(bid)) {
    throw new Error(
      `tenantId/branchId inválidos para dbName (recebido: ${tid}/${bid})`,
    );
  }
  return `phrx_tenant_${tid}_branch_${bid}`;
}

/** Placeholder temporário até o id da Branch existir (mesma transacção). */
export const BRANCH_DB_NAME_PENDING = "__phrx_db_pending__";

export function isCanonicalBranchDbName(dbName: string): boolean {
  return /^phrx_tenant_\d+_branch_\d+$/.test(dbName);
}

export function parseCanonicalBranchDbName(
  dbName: string,
): { tenantId: string; branchId: string } | null {
  const match = /^phrx_tenant_(\d+)_branch_(\d+)$/.exec(dbName);
  if (!match) return null;
  return { tenantId: match[1], branchId: match[2] };
}

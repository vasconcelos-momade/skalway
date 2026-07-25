/**
 * @skalway/audit — stub
 * Extrair de apps/phrx/backend/src/modules/tenant/audit
 */
export type AuditEvent = {
  actorId: string;
  tenantId?: string;
  action: string;
  entity: string;
  entityId?: string;
  before?: unknown;
  after?: unknown;
  at: string;
};

export const service = {
  name: "audit",
  version: "0.1.0",
  async record(_event: AuditEvent): Promise<void> {
    // TODO: persist when extracted
  },
};

console.log(`[${service.name}] stub ready — extract from phrx/api audit modules`);

import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { writeCentralAuditLog } from "../../../infrastructure/central-audit.helper";
import { runWithCentralTenant } from "../../../../../shared/context/central-tenant-context";
import {
  BRANCH_SETTING_KEY_CATEGORY,
  BRANCH_SETTING_KEYS,
  buildDefaultBranchSettings,
  type BranchSettingSeedDefaults,
} from "../../domain/branch-setting.keys";

export type BranchFiscalProfile = {
  nomeLegal: string | null;
  nuit: string | null;
  regimeFiscal: string | null;
  iva: boolean | number | null;
};

export type BranchInvoiceProfile = {
  branchId: string;
  branchNome: string | null;
  branchNuit: string | null;
  branchEmail: string | null;
  branchTelefone: string | null;
  branchEndereco: string | null;
  branchLogo: string | null;
  branchCidade: string | null;
  branchProvincia: string | null;
  moeda: string | null;
  titulo: string | null;
  footer: string | null;
};

export type BranchPrinterConfig = {
  tipo: string | null;
  larguraPapel: number | null;
  printerPadrao: string | null;
};

export type BranchSettingRow = {
  id: string;
  key: string;
  value: unknown;
  category: string;
  description: string | null;
  schemaVersion: number;
  version: number;
  updatedAt: string | null;
};

function jsonValue(raw: unknown): unknown {
  if (raw === null || raw === undefined) return null;
  if (typeof raw === "string" || typeof raw === "number" || typeof raw === "boolean") {
    return raw;
  }
  return raw;
}

function asText(value: unknown): string | null {
  if (value == null) return null;
  const text = String(value).trim();
  return text.length > 0 ? text : null;
}

function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function asBoolOrNumber(value: unknown): boolean | number | null {
  if (typeof value === "boolean" || typeof value === "number") return value;
  if (value === "true") return true;
  if (value === "false") return false;
  return asNumber(value);
}

function serializeRow(row: any): BranchSettingRow {
  return {
    id: row.id.toString(),
    key: row.key,
    value: jsonValue(row.value),
    category: row.category,
    description: row.description ?? null,
    schemaVersion: row.schemaVersion,
    version: row.version,
    updatedAt: row.updatedAt?.toISOString?.() ?? row.updatedAt ?? null,
  };
}

/**
 * Configurações por filial na Central.
 * Todas as queries obrigam tenantId + branchId (isolamento multi-tenant/filial).
 */
export class BranchSettingService {
  private get prisma() {
    return prismaCentralUnscoped as any;
  }

  async seedDefaults(params: {
    tx: any;
    tenantId: bigint;
    branchId: bigint;
    defaults: BranchSettingSeedDefaults;
  }) {
    const { tx, tenantId, branchId, defaults } = params;

    const branch = await tx.branch.findFirst({
      where: { id: branchId, tenantId, deletedAt: null },
      select: { id: true, code: true, name: true },
    });
    if (!branch) {
      throw new Error("Filial inválida para o tenant ao criar BranchSetting");
    }

    const existing = await tx.branchSetting.count({
      where: { tenantId, branchId, deletedAt: null },
    });
    if (existing > 0) {
      return { created: 0, skipped: true as const };
    }

    const items = buildDefaultBranchSettings({
      ...defaults,
      branchName: defaults.branchName || branch.name,
      branchCode: defaults.branchCode ?? branch.code,
      // Nunca herdar tenantName/email do dono — só o que for explícito.
      email: defaults.email ?? null,
      telefone: defaults.telefone ?? null,
      endereco: defaults.endereco ?? null,
      cidade: defaults.cidade ?? null,
      provincia: defaults.provincia ?? null,
      nuit: defaults.nuit ?? null,
      nomeLegal: defaults.nomeLegal ?? (defaults.branchName || branch.name),
    });

    await tx.branchSetting.createMany({
      data: items.map((item) => ({
        tenantId,
        branchId,
        key: item.key,
        value: item.value as any,
        category: item.category,
        description: item.description ?? null,
        schemaVersion: 1,
        version: 0,
      })),
    });

    return { created: items.length, skipped: false as const };
  }

  async list(
    tenantId: bigint | string,
    branchId: bigint | string,
  ): Promise<{
    branchId: string;
    branchCode: string | null;
    branchName: string | null;
    items: BranchSettingRow[];
    byKey: Record<string, unknown>;
  }> {
    const tid = BigInt(tenantId);
    const bid = BigInt(branchId);

    return runWithCentralTenant(tid.toString(), async () => {
      const branch = await this.assertBranchBelongsToTenant(this.prisma, tid, bid);
      const rows = await this.prisma.branchSetting.findMany({
        where: { tenantId: tid, branchId: bid, deletedAt: null },
        orderBy: [{ category: "asc" }, { key: "asc" }],
      });
      const items = rows.map(serializeRow);
      const byKey: Record<string, unknown> = {};
      for (const item of items) {
        byKey[item.key] = item.value;
      }
      return {
        branchId: bid.toString(),
        branchCode: branch.code ?? null,
        branchName: branch.name ?? null,
        items,
        byKey,
      };
    });
  }

  async get(tenantId: bigint | string, branchId: bigint | string, key: string) {
    const tid = BigInt(tenantId);
    const bid = BigInt(branchId);

    return runWithCentralTenant(tid.toString(), async () => {
      await this.assertBranchBelongsToTenant(this.prisma, tid, bid);
      const row = await this.prisma.branchSetting.findFirst({
        where: {
          tenantId: tid,
          branchId: bid,
          key,
          deletedAt: null,
        },
      });
      return row ? serializeRow(row) : null;
    });
  }

  async set(
    tenantId: bigint | string,
    branchId: bigint | string,
    key: string,
    value: unknown,
    options?: {
      category?: string;
      description?: string | null;
      expectedVersion?: number;
      userId?: bigint | null;
    },
  ) {
    const result = await this.updateMany(tenantId, branchId, [{ key, value }], options);
    return result.items.find((item) => item.key === key) ?? null;
  }

  async updateMany(
    tenantId: bigint | string,
    branchId: bigint | string,
    entries: Array<{ key: string; value: unknown; expectedVersion?: number }>,
    options?: { userId?: bigint | null },
  ) {
    const tid = BigInt(tenantId);
    const bid = BigInt(branchId);
    const userId = options?.userId ?? null;

    return runWithCentralTenant(tid.toString(), async () => {
      return this.prisma.$transaction(async (tx: any) => {
        await this.assertBranchBelongsToTenant(tx, tid, bid);
        const updatedItems: BranchSettingRow[] = [];

        for (const entry of entries) {
          const key = entry.key.trim();
          if (!key) continue;

          const existing = await tx.branchSetting.findFirst({
            where: { tenantId: tid, branchId: bid, key, deletedAt: null },
          });

          if (existing) {
            if (
              entry.expectedVersion != null &&
              existing.version !== entry.expectedVersion
            ) {
              throw new Error(
                `Conflito de versão em ${key}: a configuração da filial foi alterada por outro processo`,
              );
            }

            const before = serializeRow(existing);
            const updated = await tx.branchSetting.update({
              where: { id: existing.id, version: existing.version },
              data: {
                value: entry.value as any,
                version: { increment: 1 },
              },
            });
            const after = serializeRow(updated);
            await writeCentralAuditLog(
              {
                tenantId: tid,
                branchId: bid,
                userId,
                action: "UPDATE",
                entity: "BranchSetting",
                entityId: updated.id.toString(),
                oldData: before,
                newData: after,
              },
              tx,
            );
            updatedItems.push(after);
            continue;
          }

          const category =
            BRANCH_SETTING_KEY_CATEGORY[key] ?? "IDENTIDADE";
          const created = await tx.branchSetting.create({
            data: {
              tenantId: tid,
              branchId: bid,
              key,
              value: entry.value as any,
              category,
              schemaVersion: 1,
              version: 0,
            },
          });
          const after = serializeRow(created);
          await writeCentralAuditLog(
            {
              tenantId: tid,
              branchId: bid,
              userId,
              action: "CREATE",
              entity: "BranchSetting",
              entityId: created.id.toString(),
              newData: after,
            },
            tx,
          );
          updatedItems.push(after);
        }

        // Manter Branch.name alinhado se branch.name for actualizado.
        const nameEntry = entries.find((e) => e.key === BRANCH_SETTING_KEYS.name);
        if (nameEntry && asText(nameEntry.value)) {
          await tx.branch.update({
            where: { id: bid },
            data: { name: asText(nameEntry.value) },
          });
        }

        return { branchId: bid.toString(), items: updatedItems };
      });
    });
  }

  async getMap(tenantId: bigint | string, branchId: bigint | string) {
    const listed = await this.list(tenantId, branchId);
    const map = new Map<string, unknown>();
    for (const [key, value] of Object.entries(listed.byKey)) {
      map.set(key, value);
    }
    return map;
  }

  async getFiscalProfile(
    tenantId: bigint | string,
    branchId: bigint | string,
  ): Promise<BranchFiscalProfile> {
    const map = await this.getMap(tenantId, branchId);
    return {
      nomeLegal: asText(map.get(BRANCH_SETTING_KEYS.nomeLegal)),
      nuit: asText(map.get(BRANCH_SETTING_KEYS.nuit)),
      regimeFiscal: asText(map.get(BRANCH_SETTING_KEYS.regimeFiscal)),
      iva: asBoolOrNumber(map.get(BRANCH_SETTING_KEYS.iva)),
    };
  }

  async getInvoiceProfile(
    tenantId: bigint | string,
    branchId: bigint | string,
  ): Promise<BranchInvoiceProfile> {
    const listed = await this.list(tenantId, branchId);
    const map = listed.byKey;
    // Nunca usar Tenant.tenantName — só dados da filial.
    const branchNome =
      asText(map[BRANCH_SETTING_KEYS.nomeExibido]) ??
      asText(map[BRANCH_SETTING_KEYS.nomeLegal]) ??
      asText(map[BRANCH_SETTING_KEYS.name]) ??
      listed.branchName;

    return {
      branchId: String(branchId),
      branchNome,
      branchNuit: asText(map[BRANCH_SETTING_KEYS.nuit]),
      branchEmail: asText(map[BRANCH_SETTING_KEYS.email]),
      branchTelefone: asText(map[BRANCH_SETTING_KEYS.telefone]),
      branchEndereco: asText(map[BRANCH_SETTING_KEYS.endereco]),
      branchLogo: asText(map[BRANCH_SETTING_KEYS.logo]),
      branchCidade: asText(map[BRANCH_SETTING_KEYS.cidade]),
      branchProvincia: asText(map[BRANCH_SETTING_KEYS.provincia]),
      moeda: asText(map[BRANCH_SETTING_KEYS.moeda]),
      titulo: asText(map[BRANCH_SETTING_KEYS.titulo]),
      footer: asText(map[BRANCH_SETTING_KEYS.footer]),
    };
  }

  async getPrinterConfig(
    tenantId: bigint | string,
    branchId: bigint | string,
  ): Promise<BranchPrinterConfig> {
    const map = await this.getMap(tenantId, branchId);
    return {
      tipo: asText(map.get(BRANCH_SETTING_KEYS.impressaoTipo)),
      larguraPapel: asNumber(map.get(BRANCH_SETTING_KEYS.larguraPapel)),
      printerPadrao: asText(map.get(BRANCH_SETTING_KEYS.printerPadrao)),
    };
  }

  private async assertBranchBelongsToTenant(
    tx: any,
    tenantId: bigint,
    branchId: bigint,
  ) {
    const branch = await tx.branch.findFirst({
      where: { id: branchId, tenantId, deletedAt: null },
      select: { id: true, code: true, name: true },
    });
    if (!branch) {
      throw new Error("Filial inválida para o tenant");
    }
    return branch;
  }
}

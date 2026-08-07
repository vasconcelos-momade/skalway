import { BranchSettingService } from "../../../../central/branch-settings";
import { prismaCentralUnscoped } from "../../../../../infrastructure/prisma/prisma-central.service";
import { getBranchStore } from "../../../../../shared/context/branch-context";

export type TenantEmpresaProfile = {
  nome: string | null;
  nuit: string | null;
  endereco: string | null;
  email: string | null;
  telefone: string | null;
  logo?: string | null;
  cidade?: string | null;
  provincia?: string | null;
  branchId?: string | null;
};

function toNullableText(value: unknown): string | null {
  const normalized = String(value ?? "").trim();
  return normalized.length > 0 ? normalized : null;
}

/**
 * Perfil comercial/fiscal da filial activa.
 * Fonte: BranchSetting. Fallback: Branch.name (nunca Tenant.tenantName / CentralSettings).
 */
export async function resolveTenantEmpresaProfile(): Promise<TenantEmpresaProfile> {
  const { tenantId, branchId } = getBranchStore();

  try {
    const profile = await new BranchSettingService().getInvoiceProfile(
      tenantId,
      branchId,
    );
    return {
      nome: profile.branchNome,
      nuit: profile.branchNuit,
      endereco: profile.branchEndereco,
      email: profile.branchEmail,
      telefone: profile.branchTelefone,
      logo: profile.branchLogo,
      cidade: profile.branchCidade,
      provincia: profile.branchProvincia,
      branchId: profile.branchId,
    };
  } catch {
    // Branch sem settings — só nome da Branch (não Tenant).
  }

  const branch = await (prismaCentralUnscoped as any).branch.findFirst({
    where: {
      id: BigInt(branchId),
      tenantId: BigInt(tenantId),
      deletedAt: null,
    },
    select: { name: true },
  });

  return {
    nome: toNullableText(branch?.name),
    nuit: null,
    endereco: null,
    email: null,
    telefone: null,
    logo: null,
    cidade: null,
    provincia: null,
    branchId: String(branchId),
  };
}

/** Snapshot imutável a gravar na Fatura no momento da emissão. */
export async function resolveFaturaBranchSnapshot(): Promise<{
  branchId: bigint;
  branchNome: string | null;
  branchNuit: string | null;
  branchEmail: string | null;
  branchTelefone: string | null;
  branchEndereco: string | null;
  branchCidade: string | null;
  branchProvincia: string | null;
  branchLogo: string | null;
}> {
  const { branchId } = getBranchStore();
  const profile = await resolveTenantEmpresaProfile();
  return {
    branchId: BigInt(branchId),
    branchNome: profile.nome,
    branchNuit: profile.nuit,
    branchEmail: profile.email,
    branchTelefone: profile.telefone,
    branchEndereco: profile.endereco,
    branchCidade: profile.cidade ?? null,
    branchProvincia: profile.provincia ?? null,
    branchLogo: profile.logo ?? null,
  };
}

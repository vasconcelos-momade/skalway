import { describe, expect, test } from "bun:test";

/**
 * Regras de isolamento e snapshot (contrato).
 * Cobertura de integração DB fica nos use-cases de emissão;
 * estes testes documentam e validam as invariantes puras.
 */

describe("isolamento BranchSetting", () => {
  test("Branch A não partilha settings com Branch B (chave composta)", () => {
    const rows = [
      { tenantId: "1", branchId: "10", key: "branch.name", value: "A" },
      { tenantId: "1", branchId: "20", key: "branch.name", value: "B" },
    ];

    const forBranch = (tenantId: string, branchId: string) =>
      rows.filter((r) => r.tenantId === tenantId && r.branchId === branchId);

    expect(forBranch("1", "10")).toHaveLength(1);
    expect(forBranch("1", "10")[0]?.value).toBe("A");
    expect(forBranch("1", "20")[0]?.value).toBe("B");
    expect(forBranch("1", "10").some((r) => r.value === "B")).toBe(false);
  });

  test("Tenant A não acede Branch de Tenant B", () => {
    const rows = [
      { tenantId: "1", branchId: "10", key: "fiscal.nuit", value: "111" },
      { tenantId: "2", branchId: "10", key: "fiscal.nuit", value: "222" },
    ];

    const assertBelongs = (tenantId: string, branchId: string, ownerTenantId: string) => {
      if (tenantId !== ownerTenantId) {
        throw new Error("Filial inválida para o tenant");
      }
      return rows.find((r) => r.tenantId === tenantId && r.branchId === branchId);
    };

    expect(assertBelongs("1", "10", "1")?.value).toBe("111");
    expect(() => assertBelongs("1", "10", "2")).toThrow(/Filial inválida/);
  });

  test("contexto activo rejeita branchId diferente do header", () => {
    const resolveBranchId = (contextBranchId: string, paramBranchId?: string) => {
      if (paramBranchId && paramBranchId !== contextBranchId) {
        throw new Error(
          "branchId do pedido não corresponde à filial do contexto activo",
        );
      }
      return contextBranchId;
    };

    expect(resolveBranchId("10", "10")).toBe("10");
    expect(resolveBranchId("10")).toBe("10");
    expect(() => resolveBranchId("10", "99")).toThrow(/contexto activo/);
  });
});

describe("snapshot imutável da fatura", () => {
  test("alterar BranchSetting não muda fatura já emitida", () => {
    const fatura = {
      branchNome: "Nome no momento da emissão",
      branchNuit: "123456789",
      branchCidade: "Maputo",
      branchProvincia: "Maputo",
    };

    const liveSettings = {
      "branch.name": "Nome actualizado depois",
      "fiscal.nuit": "999999999",
      "branch.cidade": "Beira",
    };

    // Detalhe da fatura com snapshot prevalece sobre live settings.
    const displayNome = fatura.branchNome ?? liveSettings["branch.name"];
    const displayNuit = fatura.branchNuit ?? liveSettings["fiscal.nuit"];
    const displayCidade = fatura.branchCidade ?? liveSettings["branch.cidade"];

    expect(displayNome).toBe("Nome no momento da emissão");
    expect(displayNuit).toBe("123456789");
    expect(displayCidade).toBe("Maputo");
  });

  test("nova fatura recebe snapshot da filial (não Tenant.tenantName)", () => {
    const branchSetting = {
      "documento.nomeExibido": null,
      "fiscal.nomeLegal": "Farmácia Central Lda",
      "branch.name": "Farmácia Central",
    };
    const tenantName = "Momade Vasconcelos";

    const asText = (v: unknown) => {
      if (v == null) return null;
      const t = String(v).trim();
      return t.length > 0 ? t : null;
    };

    const branchNome =
      asText(branchSetting["documento.nomeExibido"]) ??
      asText(branchSetting["fiscal.nomeLegal"]) ??
      asText(branchSetting["branch.name"]);

    expect(branchNome).toBe("Farmácia Central Lda");
    expect(branchNome).not.toBe(tenantName);
  });

  test("CentralSettings nunca entra no perfil fiscal da filial", () => {
    const centralSettings = { companyName: "Skalway SaaS", nuit: "000000000" };
    const branchInvoiceProfile = {
      branchNome: "Filial X",
      branchNuit: null as string | null,
    };

    // Perfil fiscal da fatura só usa BranchSetting / Branch — não CentralSettings.
    const nuitUsado = branchInvoiceProfile.branchNuit ?? null;
    expect(nuitUsado).toBeNull();
    expect(nuitUsado).not.toBe(centralSettings.nuit);
    expect(branchInvoiceProfile.branchNome).not.toBe(centralSettings.companyName);
  });
});

import { describe, expect, test } from "bun:test";
import { policyToRegulacaoRow, resolveProdutoPolicy } from "./produto-dispensacao-policy";

describe("policyToRegulacaoRow", () => {
  test("persiste tipoDispensacao e flags regulatórias resolvidas", () => {
    const policy = resolveProdutoPolicy({ tipoDispensacao: "RECEITA_ESPECIAL" });
    expect(policyToRegulacaoRow(policy)).toEqual({
      tipoDispensacao: "RECEITA_ESPECIAL",
      requiresPrescription: true,
      requiresDoubleCheck: true,
      requiresPsychotropicBook: true,
      policyVersion: 3,
    });
  });

  test("VENDA_LIVRE persiste flags a false", () => {
    const policy = resolveProdutoPolicy({ tipoDispensacao: "VENDA_LIVRE" });
    expect(policyToRegulacaoRow(policy)).toEqual({
      tipoDispensacao: "VENDA_LIVRE",
      requiresPrescription: false,
      requiresDoubleCheck: false,
      requiresPsychotropicBook: false,
      policyVersion: 3,
    });
  });
});

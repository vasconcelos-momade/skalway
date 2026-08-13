import { describe, expect, test } from "bun:test";
import { buildPosServicosWhere } from "./search-servicos.use-case";

describe("SearchServicosUseCase POS filter", () => {
  test("sempre filtra apenas serviços activos", () => {
    expect(buildPosServicosWhere()).toEqual({ ativo: true });
    expect(buildPosServicosWhere("  consulta  ")).toEqual({
      ativo: true,
      nome: { contains: "consulta" },
    });
  });
});

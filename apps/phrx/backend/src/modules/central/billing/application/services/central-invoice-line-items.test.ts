import { describe, expect, test } from "bun:test";
import {
  buildCentralInvoiceLineItems,
  resolveContractMonths,
} from "./central-invoice-line-items";

describe("central-invoice-line-items", () => {
  test("resolveContractMonths: período trial de 1 mês (20/08→20/09) = 1", () => {
    expect(
      resolveContractMonths({
        periodStart: new Date("2026-08-20T00:00:00.000Z"),
        periodEnd: new Date("2026-09-19T23:59:59.999Z"),
      }),
    ).toBe(1);
  });

  test("resolveContractMonths: 2 meses exactos", () => {
    expect(
      resolveContractMonths({
        periodStart: new Date("2026-08-20T00:00:00.000Z"),
        periodEnd: new Date("2026-10-19T23:59:59.999Z"),
      }),
    ).toBe(2);
  });

  test("buildLineItems: QTD do plano = 1 e VALOR = subtotal (sem extras)", () => {
    const items = buildCentralInvoiceLineItems({
      planName: "Starter",
      planSlug: "starter",
      planMonthlyPrice: 1990,
      periodStart: new Date("2026-08-20T00:00:00.000Z"),
      periodEnd: new Date("2026-09-19T23:59:59.999Z"),
      snapshotExtraBranches: 0,
      extraBranchPrice: 990,
      amount: 1990,
    });

    expect(items).toHaveLength(1);
    expect(items[0].qty).toBe("1");
    expect(items[0].unitPrice).toBe("1990.00");
    expect(items[0].amount).toBe("1990.00");
    expect(items[0].description).toContain("1 mês");
  });

  test("buildLineItems: QTD das filiais = branches adicionais", () => {
    const items = buildCentralInvoiceLineItems({
      planName: "Starter",
      planSlug: "starter",
      planMonthlyPrice: 1990,
      periodStart: new Date("2026-08-20T00:00:00.000Z"),
      periodEnd: new Date("2026-09-19T23:59:59.999Z"),
      snapshotExtraBranches: 2,
      extraBranchPrice: 500,
      amount: 2990,
    });

    expect(items).toHaveLength(2);
    expect(items[0].qty).toBe("1");
    expect(items[0].amount).toBe("1990.00");
    expect(items[1].qty).toBe("2");
    expect(items[1].unitPrice).toBe("500.00");
    expect(items[1].amount).toBe("1000.00");
    expect(items[1].description).toContain("Filiais adicionais");
  });
});

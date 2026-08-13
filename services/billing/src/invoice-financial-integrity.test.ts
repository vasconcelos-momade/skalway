import { describe, expect, test } from "bun:test";
import {
  computePayableAmount,
  computeRemainingAmount,
} from "./invoice-financial-integrity";

describe("invoice financial integrity", () => {
  test("Total = Subtotal − Desconto; Em aberto = Total − Pago (ex.: 23880 − 5000)", () => {
    const subtotal = 23880;
    const discount = 5000;
    const paid = 0;

    const total = computePayableAmount(subtotal, discount);
    const remaining = computeRemainingAmount(subtotal, paid, discount);

    expect(total).toBe(18880);
    expect(remaining).toBe(18880);
  });

  test("Em aberto reduz com pagamento parcial", () => {
    expect(computeRemainingAmount(23880, 5000, 5000)).toBe(13880);
  });
});

import { toCents } from "./money";

export type PlanPricingInput = {
  monthlyPrice: unknown;
  extraBranchPrice?: unknown;
  includedBranches?: unknown;
  isEnterprise?: boolean;
};

export type PlanPricingResult = {
  includedBranches: number;
  extraBranches: number;
  monthlyPriceCents: number;
  extraBranchPriceCents: number;
  totalCents: number;
};

export function calculatePlanTotals(
  plan: PlanPricingInput,
  branchesUsed: number,
): PlanPricingResult {
  const includedBranches = Number(plan.includedBranches ?? 1);
  const monthlyPriceCents = toCents(plan.monthlyPrice);
  const extraBranchPriceCents = plan.isEnterprise ? 0 : toCents(plan.extraBranchPrice);
  const extraBranches = plan.isEnterprise
    ? 0
    : Math.max(0, branchesUsed - includedBranches);
  const totalCents = monthlyPriceCents + extraBranches * extraBranchPriceCents;

  return {
    includedBranches,
    extraBranches,
    monthlyPriceCents,
    extraBranchPriceCents,
    totalCents,
  };
}

#!/usr/bin/env bun
/**
 * CLI: gerar faturação mensal.
 * Uso: bun run billing:generate:monthly -- --tenant-id=1 [--dry-run] [--reference-date=2026-07-01]
 */
import { GenerateMonthlyBillingService } from "../src/modules/central/billing/application/services/generate-monthly-billing.service";

function hasFlag(name: string): boolean {
  return process.argv.includes(`--${name}`);
}

function arg(name: string): string | undefined {
  const prefix = `--${name}=`;
  const hit = process.argv.find((a) => a.startsWith(prefix));
  return hit ? hit.slice(prefix.length) : undefined;
}

const result = await new GenerateMonthlyBillingService().execute({
  tenantId: arg("tenant-id"),
  subscriptionId: arg("subscription-id"),
  referenceDate: arg("reference-date"),
  dryRun: hasFlag("dry-run"),
  includeTrial: hasFlag("include-trial"),
});

console.log(JSON.stringify(result, null, 2));

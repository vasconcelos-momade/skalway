#!/usr/bin/env bun
/**
 * CLI: processar lifecycle de subscrições.
 * Uso: bun run billing:process:lifecycle -- --reference-date=2026-07-31
 */
import { ProcessSubscriptionLifecycleService } from "../src/modules/central/billing/application/services/process-subscription-lifecycle.service";

function arg(name: string): string | undefined {
  const prefix = `--${name}=`;
  const hit = process.argv.find((a) => a.startsWith(prefix));
  return hit ? hit.slice(prefix.length) : undefined;
}

const referenceDate = arg("reference-date");

const result = await new ProcessSubscriptionLifecycleService().execute({
  referenceDate,
});

console.log(JSON.stringify(result, null, 2));

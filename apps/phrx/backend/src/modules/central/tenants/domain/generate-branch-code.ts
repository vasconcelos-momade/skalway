import { randomUUID } from "node:crypto";

/**
 * Gera um código único de branch (UID curto, seguro para MySQL identifiers).
 * Formato: 16 hex chars uppercase (ex: A1B2C3D4E5F60718).
 */
export function generateBranchCode(): string {
  return randomUUID().replace(/-/g, "").slice(0, 16).toUpperCase();
}

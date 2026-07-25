/** Formato fiscal SaaS: INV-YYYY-000001 */
export function formatInvoiceNumber(fiscalYear: number, sequence: number): string {
  return `INV-${fiscalYear}-${String(sequence).padStart(6, "0")}`;
}

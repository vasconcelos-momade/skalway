export function toCents(value: unknown): number {
  return Math.round(Number(value ?? 0) * 100);
}

export function fromCents(value: number): string {
  return (value / 100).toFixed(2);
}

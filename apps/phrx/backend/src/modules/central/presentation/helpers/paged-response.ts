import { success } from "../../../../shared/http/api-response";
import { serializeForJson } from "../../../../shared/http/serialize-json";

export type PagedListMeta = {
  page: number;
  pageSize: number;
  hasMore: boolean;
  totalCount: number;
};

export function resolvePage(page?: number): number {
  return Math.max(1, page ?? 1);
}

export function resolvePageSize(pageSize?: number, fallback = 20): number {
  return Math.min(100, Math.max(1, pageSize ?? fallback));
}

/** Resposta paginada standard (`success` + meta). */
export function pagedSuccess<T>(items: T[], meta: PagedListMeta): Response {
  return success(items, 200, meta);
}

/** Lista completa (compat) — envelope normalizado pelo middleware. */
export function listSuccess<T>(items: T[]): Response {
  return Response.json(serializeForJson(items));
}

export function slicePage<T>(
  rows: T[],
  page: number,
  pageSize: number,
): { items: T[]; hasMore: boolean } {
  return {
    items: rows.slice(0, pageSize),
    hasMore: rows.length > pageSize,
  };
}

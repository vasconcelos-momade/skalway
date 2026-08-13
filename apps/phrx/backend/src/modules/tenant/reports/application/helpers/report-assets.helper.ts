import { readFileSync } from "node:fs";
import { extname, join } from "node:path";

const ASSETS_ROOT = join(import.meta.dir, "../../assets");

const assetCache = new Map<string, string>();

const MIME_BY_EXT: Record<string, string> = {
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
};

export function loadReportAssetDataUri(
  assetName: string,
  mimeType: string,
): string {
  const cacheKey = `${assetName}:${mimeType}`;
  const cached = assetCache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const bytes = readFileSync(join(ASSETS_ROOT, assetName));
  const encoded = Buffer.from(bytes).toString("base64");
  const dataUri = `data:${mimeType};base64,${encoded}`;
  assetCache.set(cacheKey, dataUri);
  return dataUri;
}

export function resolveLogoDataUri(assetName = "logo.png"): string {
  const ext = extname(assetName).toLowerCase();
  const mimeType = MIME_BY_EXT[ext] ?? "image/png";
  return loadReportAssetDataUri(assetName, mimeType);
}

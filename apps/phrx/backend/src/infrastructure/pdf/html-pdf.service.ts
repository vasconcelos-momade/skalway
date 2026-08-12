import type { Browser } from "puppeteer";
import { buildSimplePdfFromLines } from "./simple-pdf.builder";

export type HtmlPdfPageSize = "A4" | "LETTER";
export type HtmlPdfOrientation = "portrait" | "landscape";

export type HtmlPdfMargins = {
  top?: string;
  right?: string;
  bottom?: string;
  left?: string;
};

export type HtmlPdfRenderOptions = {
  html: string;
  pageSize?: HtmlPdfPageSize;
  orientation?: HtmlPdfOrientation;
  margins?: HtmlPdfMargins;
  displayHeaderFooter?: boolean;
  headerTemplate?: string;
  footerTemplate?: string;
  preferCSSPageSize?: boolean;
  printBackground?: boolean;
  /** Used only if Puppeteer fails. */
  fallbackLines?: string[];
};

/** Defaults aligned with institutional @page { margin: 12mm 15mm }. */
const DEFAULT_MARGINS: Required<HtmlPdfMargins> = {
  top: "12mm",
  right: "15mm",
  bottom: "12mm",
  left: "15mm",
};

let browserPromise: Promise<Browser> | null = null;

async function getBrowser(): Promise<Browser> {
  if (!browserPromise) {
    browserPromise = (async () => {
      const puppeteer = await import("puppeteer");
      const browser = await puppeteer.default.launch({
        headless: true,
        executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
        args: ["--no-sandbox", "--disable-setuid-sandbox"],
      });
      browser.on("disconnected", () => {
        browserPromise = null;
      });
      return browser;
    })().catch((error) => {
      browserPromise = null;
      throw error;
    });
  }
  return browserPromise;
}

/**
 * Central HTML → PDF renderer (Puppeteer).
 * Callers supply HTML (Handlebars or other); this service only renders.
 */
export async function renderHtmlToPdf(
  options: HtmlPdfRenderOptions,
): Promise<Uint8Array> {
  const {
    html,
    pageSize = "A4",
    orientation = "portrait",
    margins = DEFAULT_MARGINS,
    displayHeaderFooter = false,
    headerTemplate = "<div></div>",
    footerTemplate,
    preferCSSPageSize = false,
    printBackground = true,
    fallbackLines = ["Nao foi possivel gerar o PDF."],
  } = options;

  try {
    const browser = await getBrowser();
    const page = await browser.newPage();
    try {
      await page.setContent(html, { waitUntil: "networkidle0" });
      const pdfBuffer = await page.pdf({
        format: pageSize,
        landscape: orientation === "landscape",
        printBackground,
        preferCSSPageSize,
        displayHeaderFooter,
        headerTemplate: displayHeaderFooter ? headerTemplate : undefined,
        footerTemplate:
          displayHeaderFooter && footerTemplate ? footerTemplate : undefined,
        margin: {
          top: margins.top ?? DEFAULT_MARGINS.top,
          right: margins.right ?? DEFAULT_MARGINS.right,
          bottom: margins.bottom ?? DEFAULT_MARGINS.bottom,
          left: margins.left ?? DEFAULT_MARGINS.left,
        },
      });
      return new Uint8Array(pdfBuffer);
    } finally {
      await page.close().catch(() => undefined);
    }
  } catch {
    return buildSimplePdfFromLines(fallbackLines);
  }
}

/** Graceful shutdown helper for process exit hooks. */
export async function closeHtmlPdfBrowser(): Promise<void> {
  if (!browserPromise) return;
  try {
    const browser = await browserPromise;
    await browser.close();
  } catch {
    // ignore
  } finally {
    browserPromise = null;
  }
}

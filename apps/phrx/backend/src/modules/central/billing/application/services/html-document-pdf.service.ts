import { buildSimplePdfFromLines } from "../../../../tenant/reports/application/templates/pdf-html.converter";

/**
 * Converte HTML A4 em PDF via Puppeteer (mesmo motor dos relatórios tenant).
 * Sem footer "Pharma ERP" — adequado a documentos oficiais da Central.
 */
export async function renderHtmlDocumentToPdf(
  html: string,
  fallbackLines: string[] = [],
): Promise<Uint8Array> {
  try {
    const puppeteer = await import("puppeteer");
    const browser = await puppeteer.default.launch({
      headless: true,
      executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
    });

    try {
      const page = await browser.newPage();
      await page.setContent(html, { waitUntil: "networkidle0" });
      const pdfBuffer = await page.pdf({
        format: "A4",
        printBackground: true,
        preferCSSPageSize: true,
        margin: {
          top: "10mm",
          right: "10mm",
          bottom: "12mm",
          left: "10mm",
        },
      });
      return new Uint8Array(pdfBuffer);
    } finally {
      await browser.close();
    }
  } catch {
    return buildSimplePdfFromLines(
      fallbackLines.length > 0
        ? fallbackLines
        : ["Factura SaaS", "Nao foi possivel gerar o PDF HTML."],
    );
  }
}

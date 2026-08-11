import { renderHtmlToPdf } from "../../../../../infrastructure/pdf";

/**
 * Converte HTML A4 em PDF via o serviço central Puppeteer.
 * Sem footer "Pharma ERP" — adequado a documentos oficiais da Central.
 */
export async function renderHtmlDocumentToPdf(
  html: string,
  fallbackLines: string[] = [],
): Promise<Uint8Array> {
  return renderHtmlToPdf({
    html,
    pageSize: "A4",
    orientation: "portrait",
    preferCSSPageSize: true,
    displayHeaderFooter: false,
    margins: {
      top: "10mm",
      right: "10mm",
      bottom: "12mm",
      left: "10mm",
    },
    fallbackLines:
      fallbackLines.length > 0
        ? fallbackLines
        : ["Factura SaaS", "Nao foi possivel gerar o PDF HTML."],
  });
}

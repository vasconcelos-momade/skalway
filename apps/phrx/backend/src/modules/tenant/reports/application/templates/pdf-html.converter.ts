import { type ReportDefinition } from "../types/report.types";
import { renderInstitutionalReportTextLines } from "./institutional-report.template";
import {
  buildSimplePdfFromLines,
  renderHtmlToPdf,
} from "../../../../../infrastructure/pdf";

export { buildSimplePdfFromLines };

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function resolvePdfFormat(definition: ReportDefinition): {
  pageSize: "A4" | "LETTER";
  orientation: "portrait" | "landscape";
} {
  // Default institutional reports to A4 Portrait (vertical).
  const orientation =
    definition.pdf?.orientation ?? definition.orientation ?? "portrait";
  const pageSize = definition.pdf?.pageSize ?? definition.pageSize ?? "A4";

  return {
    pageSize,
    orientation: orientation === "landscape" ? "landscape" : "portrait",
  };
}

function buildInstitutionalFooterTemplate(definition: ReportDefinition): string {
  const pharmacyName = escapeHtml(definition.institution?.pharmacyName);
  const branchName = escapeHtml(definition.institution?.branchName);
  const generatedBy = escapeHtml(definition.generatedBy);

  return `
      <div style="width:100%; padding:0 15mm; font-family: Arial, Helvetica, sans-serif; font-size:9px; color:#555; box-sizing:border-box;">
        <div style="border-top:1px solid #059669; padding-top:4px; display:flex; justify-content:space-between; gap:8px;">
          <div style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
            <span style="font-weight:700; color:#059669;">Skalway PhRx</span>
            <span style="margin:0 6px; color:#777;">|</span>
            <span>${pharmacyName}</span>
            <span style="margin:0 6px; color:#777;">|</span>
            <span>${branchName}</span>
          </div>
          <div style="text-align:center; white-space:nowrap;">
            <span>Utilizador: ${generatedBy}</span>
          </div>
          <div style="text-align:right; white-space:nowrap;">
            <span>Pagina </span>
            <span class="pageNumber" style="margin:0 4px;"></span>
            <span>de</span>
            <span class="totalPages" style="margin-left:4px;"></span>
          </div>
        </div>
      </div>
    `;
}

/**
 * Institutional reports: Handlebars HTML → Puppeteer PDF via shared HtmlPdf service.
 */
export async function convertHtmlToPdf(
  html: string,
  definition: ReportDefinition,
): Promise<Uint8Array> {
  const { pageSize, orientation } = resolvePdfFormat(definition);

  return renderHtmlToPdf({
    html,
    pageSize,
    orientation,
    preferCSSPageSize: true,
    displayHeaderFooter: true,
    headerTemplate: "<div></div>",
    footerTemplate: buildInstitutionalFooterTemplate(definition),
    // Match @page { margin: 12mm 15mm } so header/footer bands align with CSS insets.
    margins: {
      top: "12mm",
      right: "15mm",
      bottom: "12mm",
      left: "15mm",
    },
    fallbackLines: renderInstitutionalReportTextLines(definition),
  });
}

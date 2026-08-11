import { type ReportDefinition } from "../types/report.types";
import { renderInstitutionalReportHtml } from "../templates/html-template.renderer";
import { convertHtmlToPdf } from "../templates/pdf-html.converter";

/**
 * Orquestra relatórios institucionais: definição → Handlebars HTML → Puppeteer PDF.
 * Dados e regras ficam nos providers; este serviço só monta e renderiza.
 */
export class ReportPdfService {
  static async generate(definition: ReportDefinition): Promise<Uint8Array> {
    const html = renderInstitutionalReportHtml(definition);
    return convertHtmlToPdf(html, definition);
  }
}

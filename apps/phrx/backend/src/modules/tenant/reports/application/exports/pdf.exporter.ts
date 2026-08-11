import {
  type ReportArtifact,
  type ReportDefinition,
  type ReportDisposition,
  type ReportExporter,
} from "../types/report.types";
import { toReportFileName } from "../helpers/report-export.helper";
import { ReportPdfService } from "../services/report-pdf.service";

export class PdfExporter implements ReportExporter {
  readonly format = "pdf" as const;

  async export(
    definition: ReportDefinition,
    disposition: ReportDisposition,
  ): Promise<ReportArtifact> {
    const bytes = await ReportPdfService.generate(definition);

    return {
      bytes,
      fileName: `${toReportFileName(definition.fileBaseName)}.pdf`,
      contentType: "application/pdf",
      disposition,
    };
  }
}

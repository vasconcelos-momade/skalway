import 'dart:typed_data';

import '../../../../../core/contracts/pagination_response.dart';
import '../entities/invoice_detail.dart';
import '../entities/invoice_summary.dart';

abstract class InvoiceRepository {
  Future<PaginationResponse<InvoiceSummary>> listInvoices(InvoiceQuery query);

  Future<InvoiceDetail> getInvoiceDetail(String invoiceId);

  Future<({Uint8List bytes, String fileName, String contentType})> getInvoicePdf(
    String invoiceId,
  );

  Future<
      ({
        Uint8List bytes,
        String fileName,
        String contentType,
        String mode,
        String? tipo,
      })> getInvoicePrintArtifact(String invoiceId);

  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  });
}

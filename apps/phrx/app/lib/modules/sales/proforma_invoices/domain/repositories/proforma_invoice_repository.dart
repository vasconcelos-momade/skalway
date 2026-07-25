import '../entities/proforma_invoice.dart';
import '../entities/proforma_invoice_cart_line.dart';

abstract class ProformaInvoiceRepository {
  Future<ProformaInvoiceCreateResult> createProformaInvoice({
    required String cliente,
    String? clienteId,
    String? nuit,
    String? contacto,
    double? descontoGeral,
    required DateTime validade,
    String? observacoes,
    required List<ProformaInvoiceCartLine> lines,
  });

  Future<ProformaInvoiceDetail> getProformaInvoice(String proformaInvoiceId);

  Future<ProformaInvoiceDetail> updateProformaInvoiceHeader({
    required String proformaInvoiceId,
    required String cliente,
    String? clienteId,
    String? nuit,
    String? contacto,
    double? descontoGeral,
    required DateTime validade,
    String? observacoes,
  });

  Future<ProformaInvoiceDetail> addProformaInvoiceItem({
    required String proformaInvoiceId,
    required ProformaInvoiceCartLine line,
  });

  Future<ProformaInvoiceDetail> updateProformaInvoiceItem({
    required String proformaInvoiceId,
    required String itemId,
    required ProformaInvoiceCartLine line,
  });

  Future<ProformaInvoiceDetail> removeProformaInvoiceItem({
    required String proformaInvoiceId,
    required String itemId,
  });

  Future<ProformaInvoiceDetail> rejectProformaInvoice({
    required String proformaInvoiceId,
    String? observacoes,
  });

  Future<ProformaInvoiceDetail> approveProformaInvoice({
    required String proformaInvoiceId,
    String? observacoes,
  });

  Future<List<ProformaInvoiceSummary>> listProformaInvoiceHistory({
    String? query,
    int page,
    int pageSize,
  });
}

import '../../../../../core/contracts/pagination_response.dart';
import '../../../invoices/domain/entities/invoice_summary.dart';
import '../entities/sales_history.dart';

abstract class SalesHistoryRepository {
  Future<PaginationResponse<InvoiceSummary>> listSales(SalesHistoryQuery query);

  Future<SalesHistoryDashboard> getDashboard({
    DateTime? dateFrom,
    DateTime? dateTo,
  });
}

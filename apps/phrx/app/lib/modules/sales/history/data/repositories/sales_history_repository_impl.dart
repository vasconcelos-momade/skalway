import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../../invoices/domain/entities/invoice_summary.dart';
import '../../domain/entities/sales_history.dart';
import '../../domain/repositories/sales_history_repository.dart';
import '../datasources/sales_history_remote_datasource.dart';

class SalesHistoryRepositoryImpl implements SalesHistoryRepository {
  SalesHistoryRepositoryImpl(this._remote);

  final SalesHistoryRemoteDataSource _remote;

  @override
  Future<PaginationResponse<InvoiceSummary>> listSales(
    SalesHistoryQuery query,
  ) async {
    final response = await _remote.listSales(query);
    return PaginationResponse<InvoiceSummary>(
      items: response.items.map((m) => m.toEntity()).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
      summary: response.summary,
    );
  }

  @override
  Future<SalesHistoryDashboard> getDashboard({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
      _remote.getDashboard(dateFrom: dateFrom, dateTo: dateTo);
}

final salesHistoryRepositoryProvider = Provider<SalesHistoryRepository>((ref) {
  return SalesHistoryRepositoryImpl(ref.watch(salesHistoryRemoteDataSourceProvider));
});

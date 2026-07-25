import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cashflow_operation.dart';
import '../../domain/repositories/cashflow_repository.dart';
import '../datasources/cashflow_remote_datasource.dart';

class CashflowRepositoryImpl implements CashflowRepository {
  CashflowRepositoryImpl(this._remote);

  final CashflowRemoteDataSource _remote;

  @override
  Future<CashflowContext> getContext() => _remote.getContext();

  @override
  Future<CashflowMovementsPage> listMovements({
    Map<String, dynamic>? queryParameters,
    required int page,
    required int pageSize,
    String? sortBy,
    String sortDir = 'desc',
  }) {
    return _remote.listMovements(
      queryParameters: queryParameters,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortDir: sortDir,
    );
  }

  @override
  Future<CashflowOperationResponse> registerOperation({
    required CashflowOperationKind kind,
    required CashflowOperationRequest request,
  }) {
    return _remote.registerOperation(kind: kind, request: request);
  }
}

final cashflowRepositoryProvider = Provider<CashflowRepository>((ref) {
  return CashflowRepositoryImpl(ref.watch(cashflowRemoteDataSourceProvider));
});

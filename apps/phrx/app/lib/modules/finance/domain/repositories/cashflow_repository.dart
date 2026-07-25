import '../entities/cashflow_operation.dart';

abstract class CashflowRepository {
  Future<CashflowContext> getContext();

  Future<CashflowMovementsPage> listMovements({
    Map<String, dynamic>? queryParameters,
    required int page,
    required int pageSize,
    String? sortBy,
    String sortDir = 'desc',
  });

  Future<CashflowOperationResponse> registerOperation({
    required CashflowOperationKind kind,
    required CashflowOperationRequest request,
  });
}

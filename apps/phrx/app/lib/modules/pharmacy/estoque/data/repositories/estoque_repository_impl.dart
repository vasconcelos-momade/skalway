import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/estoque_dashboard.dart';
import '../../domain/entities/estoque_item.dart';
import '../../domain/repositories/estoque_repository.dart';
import '../datasources/estoque_remote_datasource.dart';

class EstoqueRepositoryImpl implements EstoqueRepository {
  EstoqueRepositoryImpl(this._remote);

  final EstoqueRemoteDataSource _remote;

  @override
  Future<EstoqueDashboard> fetchDashboard() async {
    final model = await _remote.fetchDashboard();
    return model.toEntity();
  }

  @override
  Future<PaginationResponse<EstoqueItem>> search({
    String? query,
    String? categoriaId,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? semStock,
    bool? aExpirar,
    bool? expirado,
    String? validadeDe,
    String? validadeAte,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await _remote.search(
      query: query,
      categoriaId: categoriaId,
      fornecedorId: fornecedorId,
      estadoSanitario: estadoSanitario,
      disponibilidade: disponibilidade,
      semStock: semStock,
      aExpirar: aExpirar,
      expirado: expirado,
      validadeDe: validadeDe,
      validadeAte: validadeAte,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    return PaginationResponse<EstoqueItem>(
      items: response.items.map((item) => item.toEntity()).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }
}

final estoqueRepositoryProvider = Provider<EstoqueRepository>(
  (ref) => EstoqueRepositoryImpl(ref.watch(estoqueRemoteDataSourceProvider)),
);

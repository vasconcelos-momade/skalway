import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/pdv_service.dart';
import '../../domain/repositories/pdv_service_repository.dart';
import '../datasources/pdv_service_remote_datasource.dart';
import '../models/pdv_service_model.dart';

class PdvServiceRepositoryImpl implements PdvServiceRepository {
  PdvServiceRepositoryImpl(this._remoteDataSource);

  final PdvServiceRemoteDataSource _remoteDataSource;

  @override
  Future<PaginationResponse<PdvService>> searchServices({
    String? query,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remoteDataSource.searchServices(
      query: query,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<PdvService>(
      items: response.items.map(_toEntity).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  PdvService _toEntity(PdvServiceModel model) {
    return PdvService(
      id: model.id,
      nome: model.nome,
      preco: model.preco,
      tipoServicoClinico: model.tipoServicoClinico,
    );
  }
}

final pdvServiceRepositoryProvider = Provider<PdvServiceRepository>((ref) {
  return PdvServiceRepositoryImpl(ref.watch(pdvServiceRemoteDataSourceProvider));
});

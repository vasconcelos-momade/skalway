import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/inventario.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../datasources/inventario_remote_datasource.dart';
import '../models/inventario_model.dart';

class InventarioRepositoryImpl implements InventarioRepository {
  InventarioRepositoryImpl(this._remoteDataSource);

  final InventarioRemoteDataSource _remoteDataSource;

  @override
  Future<InventarioDetalhe> abrirInventario(
    AbrirInventarioRequest request,
  ) async {
    final response = await _remoteDataSource.abrirInventario(
      AbrirInventarioRequestModel.fromEntity(request),
    );
    return response.toEntity();
  }

  @override
  Future<List<InventarioResumo>> listarInventarios({
    InventarioStatus? status,
  }) async {
    final response = await _remoteDataSource.listarInventarios(status: status);
    return response.map((item) => item.toEntity()).toList();
  }

  @override
  Future<PaginationResponse<InventarioItem>> listarItensInventario({
    required String inventarioId,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _remoteDataSource.listarItensInventario(
      inventarioId: inventarioId,
      query: query,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<InventarioItem>(
      items: response.items.map((item) => item.toEntity()).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      summary: response.summary,
    );
  }

  @override
  Future<InventarioDetalhe> obterInventario(String inventarioId) async {
    final response = await _remoteDataSource.obterInventario(inventarioId);
    return response.toEntity();
  }

  @override
  Future<InventarioDetalhe> iniciarContagem(String inventarioId) async {
    final response = await _remoteDataSource.iniciarContagem(inventarioId);
    return response.toEntity();
  }

  @override
  Future<InventarioItem> registarContagem({
    required String inventarioId,
    required String itemId,
    required double estoqueContado,
  }) async {
    final response = await _remoteDataSource.registarContagem(
      inventarioId: inventarioId,
      itemId: itemId,
      estoqueContado: estoqueContado,
    );
    return response.toEntity();
  }

  @override
  Future<InventarioDetalhe> reconciliar(String inventarioId) async {
    final response = await _remoteDataSource.reconciliar(inventarioId);
    return response.toEntity();
  }

  @override
  Future<InventarioDetalhe> cancelar(String inventarioId) async {
    final response = await _remoteDataSource.cancelar(inventarioId);
    return response.toEntity();
  }
}

final inventarioRepositoryProvider = Provider<InventarioRepository>((ref) {
  return InventarioRepositoryImpl(
    ref.watch(inventarioRemoteDataSourceProvider),
  );
});

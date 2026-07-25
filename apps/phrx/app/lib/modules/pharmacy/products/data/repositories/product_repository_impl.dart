import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_tax_rule.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<String?> fetchCatalogVersion() => _remoteDataSource.fetchCatalogVersion();

  @override
  Future<Product> getProduct(String id) async {
    final model = await _remoteDataSource.getProduct(id);
    return _toEntity(model);
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final model = await _remoteDataSource.createProduct(payload);
    return _toEntity(model);
  }

  @override
  Future<Product> updateProduct(String id, Map<String, dynamic> payload) async {
    final model = await _remoteDataSource.updateProduct(id, payload);
    return _toEntity(model);
  }

  @override
  Future<void> deleteProduct(String id) => _remoteDataSource.deleteProduct(id);

  @override
  Future<List<ProductTaxRule>> listTaxRules() => _remoteDataSource.listTaxRules();

  @override
  Future<PaginationResponse<Product>> searchMasterProducts({
    String? query,
    String? barcode,
    String? categoriaId,
    String? fornecedorId,
    String? tipoDispensacao,
    bool? ativo,
    bool includeInactive = false,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _remoteDataSource.searchMasterProducts(
      query: query,
      barcode: barcode,
      categoriaId: categoriaId,
      fornecedorId: fornecedorId,
      tipoDispensacao: tipoDispensacao,
      ativo: ativo,
      includeInactive: includeInactive,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<Product>(
      items: response.items.map(_toEntity).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  @override
  Future<PaginationResponse<Product>> searchProducts({
    String? query,
    String? barcode,
    String? categoriaId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remoteDataSource.searchProducts(
      query: query,
      barcode: barcode,
      categoriaId: categoriaId,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<Product>(
      items: response.items.map(_toEntity).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  Product _toEntity(ProductModel model) {
    return Product(
      id: model.id,
      nomeComercial: model.nomeComercial,
      nomeGenerico: model.nomeGenerico,
      dosagem: model.dosagem,
      forma: model.forma,
      apresentacao: model.apresentacao,
      ativo: model.ativo,
      barcode: model.barcode,
      categoriaId: model.categoriaId,
      categoriaNome: model.categoriaNome,
      categoriaCodigoFnm: model.categoriaCodigoFnm,
      tipoDispensacao: model.tipoDispensacao,
      requiresPrescription: model.requiresPrescription,
      requiresDoubleCheck: model.requiresDoubleCheck,
      requiresPsychotropicBook: model.requiresPsychotropicBook,
      antimicrobiano: model.antimicrobiano,
      requiresManualReview: model.requiresManualReview,
      precoVenda: model.precoVenda,
      estoqueAtual: model.estoqueAtual,
      estoqueMinimo: model.estoqueMinimo,
      numLotes: model.numLotes,
      lote: model.lote,
      dataValidade: model.dataValidade,
      proximaValidade: model.proximaValidade,
      createdAt: model.createdAt,
      taxRule: model.taxRule,
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._remote);

  final CustomerRemoteDataSource _remote;

  @override
  Future<PaginationResponse<CustomerSummary>> listCustomers(
    CustomerQuery query,
  ) async {
    final response = await _remote.listCustomers(query);
    return PaginationResponse<CustomerSummary>(
      items: response.items.map((m) => m.toEntity()).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
      summary: response.summary,
    );
  }

  @override
  Future<CustomerDashboard> getDashboard() => _remote.getDashboard();

  @override
  Future<CustomerDetail> getCustomer(String id) async {
    final model = await _remote.getCustomer(id);
    return model.toEntity();
  }

  @override
  Future<CustomerDetail> createCustomer(CustomerFormPayload payload) async {
    final model = await _remote.createCustomer(payload.toJson());
    return model.toEntity();
  }

  @override
  Future<CustomerDetail> updateCustomer(
    String id,
    CustomerFormPayload payload,
  ) async {
    final model = await _remote.updateCustomer(id, payload.toJson());
    return model.toEntity();
  }

  @override
  Future<void> deleteCustomer(String id) => _remote.deleteCustomer(id);

  @override
  Future<PaginationResponse<CustomerFaturaRef>> listCustomerFaturas(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remote.listCustomerFaturas(
      id,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<CustomerFaturaRef>(
      items: response.items.map(_mapFatura).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  @override
  Future<PaginationResponse<CustomerContaReceber>> listCustomerContasReceber(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remote.listCustomerContasReceber(
      id,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<CustomerContaReceber>(
      items: response.items.map(_mapConta).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  @override
  Future<PaginationResponse<CustomerReceitaRef>> listCustomerReceitas(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remote.listCustomerReceitas(
      id,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<CustomerReceitaRef>(
      items: response.items.map(_mapReceita).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  @override
  Future<PaginationResponse<CustomerAuditEntry>> listCustomerAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _remote.listCustomerAudit(
      id,
      page: page,
      pageSize: pageSize,
    );
    return PaginationResponse<CustomerAuditEntry>(
      items: response.items.map(_mapAudit).toList(),
      page: response.page,
      pageSize: response.pageSize,
      hasMore: response.hasMore,
      totalCount: response.totalCount,
    );
  }

  CustomerFaturaRef _mapFatura(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    final user = json['user'];
    return CustomerFaturaRef(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      serie: json['serie']?.toString(),
      total: asDouble(json['total']),
      estado: json['estado']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      userNome: user is Map<String, dynamic> ? user['nome']?.toString() : null,
    );
  }

  CustomerContaReceber _mapConta(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return 0;
    }

    final fatura = json['fatura'];
    return CustomerContaReceber(
      id: json['id']?.toString() ?? '',
      valor: asDouble(json['valor']),
      saldo: asDouble(json['saldo']),
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      vencimento: json['vencimento'] != null
          ? DateTime.tryParse(json['vencimento'].toString())
          : null,
      faturaNumero: fatura is Map<String, dynamic>
          ? fatura['numero']?.toString()
          : null,
    );
  }

  CustomerReceitaRef _mapReceita(Map<String, dynamic> json) {
    return CustomerReceitaRef(
      id: json['id']?.toString() ?? '',
      dataReceita: DateTime.tryParse(json['dataReceita']?.toString() ?? '') ??
          DateTime.now(),
      medicoNome: json['medicoNome']?.toString(),
      numeroReceita: json['numeroReceita']?.toString(),
      unidadeSanitaria: json['unidadeSanitaria']?.toString(),
    );
  }

  CustomerAuditEntry _mapAudit(Map<String, dynamic> json) {
    final user = json['user'];
    return CustomerAuditEntry(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      userNome: user is Map<String, dynamic> ? user['nome']?.toString() : null,
    );
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.watch(customerRemoteDataSourceProvider));
});

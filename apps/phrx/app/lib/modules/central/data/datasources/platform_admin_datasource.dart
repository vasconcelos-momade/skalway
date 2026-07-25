import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/platform_entities.dart';

class PlatformAdminDataSource {
  PlatformAdminDataSource(this._dio);

  final Dio _dio;

  Future<List<PlatformTenantSummary>> fetchTenants() async {
    final data = await _getList(ApiConstants.centralTenants);
    return data.map(_mapTenantSummary).toList();
  }

  Future<PlatformTenantDetail> fetchTenantDetail(String tenantId) async {
    final data = await _getMap('${ApiConstants.centralTenants}/$tenantId');
    final branchesRaw = data['branches'];
    final branches = branchesRaw is List
        ? branchesRaw
            .whereType<Map<String, dynamic>>()
            .map(_mapBranch)
            .toList()
        : <PlatformBranch>[];

    final subscription = await fetchSubscription(tenantId);

    return PlatformTenantDetail(
      summary: _mapTenantSummary(data),
      branches: branches,
      subscription: subscription,
    );
  }

  Future<PlatformSubscription?> fetchSubscription(String tenantId) async {
    try {
      final data = await _getMap(
        '${ApiConstants.centralTenants}/$tenantId/subscription',
      );
      return _mapSubscription(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<PlatformInvoice>> fetchInvoices(String tenantId) async {
    final data = await _getList(
      '${ApiConstants.centralTenants}/$tenantId/invoices',
      query: {'limit': '50'},
    );
    return data.map((row) => _mapInvoice(row, tenantId)).toList();
  }

  Future<List<PlatformPayment>> fetchPayments(String tenantId) async {
    final data = await _getList(
      '${ApiConstants.centralTenants}/$tenantId/payments',
      query: {'limit': '50'},
    );
    return data.map((row) => _mapPayment(row)).toList();
  }

  Future<PlatformDashboardStats> fetchDashboardStats() async {
    final tenants = await fetchTenants();
    final active =
        tenants.where((t) => t.status == 'ativo' || t.status == 'active').length;
    final trial = tenants.where((t) => t.status == 'trial').length;
    final suspended = tenants
        .where((t) => t.status == 'suspenso' || t.status == 'suspended')
        .length;
    final branches = tenants.fold<int>(0, (sum, t) => sum + t.branchCount);
    final revenue = tenants.fold<double>(
      0,
      (sum, t) => sum + (t.monthlyValue ?? 0),
    );

    final recent = List<PlatformTenantSummary>.from(tenants)
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    final alerts = <String>[];
    for (final t in tenants) {
      if (t.status == 'grace') {
        alerts.add('${t.companyName} em período de graça');
      }
      if (t.status == 'trial' && t.nextBillingAt != null) {
        alerts.add('Trial de ${t.companyName} expira em breve');
      }
    }

    return PlatformDashboardStats(
      totalClients: tenants.length,
      activeClients: active,
      trialClients: trial,
      suspendedClients: suspended,
      monthlyRevenue: revenue,
      totalBranches: branches,
      recentTenants: recent.take(5).toList(),
      alerts: alerts.take(6).toList(),
    );
  }

  Future<List<PlatformInvoice>> fetchAllInvoices() async {
    final tenants = await fetchTenants();
    final all = <PlatformInvoice>[];
    for (final tenant in tenants.take(20)) {
      try {
        final invoices = await fetchInvoices(tenant.id);
        all.addAll(invoices);
      } catch (_) {}
    }
    return all;
  }

  Future<List<PlatformPayment>> fetchAllPayments() async {
    final tenants = await fetchTenants();
    final all = <PlatformPayment>[];
    for (final tenant in tenants.take(20)) {
      try {
        final payments = await fetchPayments(tenant.id);
        all.addAll(payments);
      } catch (_) {}
    }
    return all;
  }

  Future<RegisterTenantResult> registerTenant(RegisterTenantPayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.centralTenants,
      data: payload.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw const ApiFailure('Resposta inválida.');
    }
    if (data['success'] == false) {
      throw ApiFailure(_errorMessage(data));
    }
    final body = ApiEnvelope.unwrapMap(data);
    final branch = body['branch'];
    return RegisterTenantResult(
      id: '${body['id']}',
      companyName: body['companyName'] as String? ?? payload.nomeEmpresa,
      tenantName: body['name'] as String? ?? payload.nomeTenant,
      branchCode: branch is Map ? branch['code'] as String? : null,
    );
  }

  Future<void> confirmPayment({
    required String tenantId,
    required String paymentId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiConstants.centralTenants}/$tenantId/payments/$paymentId/confirm',
    );
    final data = response.data;
    if (data == null) {
      throw const ApiFailure('Resposta inválida.');
    }
    if (data['success'] == false) {
      throw ApiFailure(_errorMessage(data));
    }
  }

  Future<Uint8List> downloadInvoicePdf({
    required String tenantId,
    required String invoiceId,
  }) async {
    final response = await _dio.get<List<int>>(
      '${ApiConstants.centralTenants}/$tenantId/invoices/$invoiceId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const ApiFailure('PDF da fatura indisponível.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    final data = response.data;
    if (data == null) {
      throw const ApiFailure('Resposta inválida.');
    }
    if (data['success'] == false) {
      throw ApiFailure(_errorMessage(data));
    }
    final direct = data['data'];
    if (direct is List) {
      return direct.whereType<Map<String, dynamic>>().toList();
    }
    final unwrapped = ApiEnvelope.unwrapMap(data);
    final items = unwrapped['items'] ?? unwrapped['data'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    if (unwrapped.containsKey('id')) {
      return [unwrapped];
    }
    return [];
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    final data = response.data;
    if (data == null) {
      throw const ApiFailure('Resposta inválida.');
    }
    if (data['success'] == false) {
      throw ApiFailure(_errorMessage(data));
    }
    return ApiEnvelope.unwrapMap(data);
  }

  String _errorMessage(Map<String, dynamic> data) {
    final err = data['error'];
    if (err is Map) {
      final msg = err['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Erro na API central.';
  }

  PlatformTenantSummary _mapTenantSummary(Map<String, dynamic> json) {
    final branches = json['branches'];
    final branchCount = branches is List ? branches.length : 0;
    final sub = json['subscription'];
    String? planName;
    double? monthlyValue;
    DateTime? nextBilling;
    if (sub is Map<String, dynamic>) {
      planName = sub['planName'] as String? ?? sub['plan']?.toString();
      monthlyValue = _toDouble(sub['monthlyPrice'] ?? sub['price']);
      nextBilling = _toDate(sub['nextBillingAt'] ?? sub['currentPeriodEnd']);
    }

    return PlatformTenantSummary(
      id: '${json['id']}',
      companyName: json['companyName'] as String? ??
          json['nomeEmpresa'] as String? ??
          '',
      tenantName:
          json['name'] as String? ?? json['nomeTenant'] as String? ?? '',
      status: json['status'] as String? ?? 'ativo',
      country: json['country'] as String? ?? 'MZ',
      branchCount: branchCount,
      planName: planName,
      monthlyValue: monthlyValue,
      nextBillingAt: nextBilling,
      createdAt: _toDate(json['createdAt']),
    );
  }

  PlatformBranch _mapBranch(Map<String, dynamic> json) => PlatformBranch(
        id: '${json['id']}',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        lastSyncAt: _toDate(json['lastSyncAt']),
        dbName: json['dbName'] as String?,
        connectionStatus: json['connectionStatus'] as String?,
      );

  PlatformSubscription _mapSubscription(Map<String, dynamic> json) =>
      PlatformSubscription(
        planName: json['planName'] as String? ??
            json['plan']?['name'] as String? ??
            '—',
        status: json['status'] as String? ?? 'ativo',
        startDate: _toDate(json['startDate'] ?? json['currentPeriodStart']),
        endDate: _toDate(json['endDate'] ?? json['currentPeriodEnd']),
        trialEndsAt: _toDate(json['trialEndsAt']),
        includedBranches: json['includedBranches'] as int? ?? 0,
        usedBranches: json['usedBranches'] as int? ?? 0,
        monthlyPrice: _toDouble(json['monthlyPrice'] ?? json['price']),
      );

  PlatformInvoice _mapInvoice(Map<String, dynamic> json, String tenantId) =>
      PlatformInvoice(
        id: '${json['id']}',
        number: json['number'] as String? ?? json['invoiceNumber'] as String? ?? '—',
        tenantName: json['tenantName'] as String? ?? tenantId,
        planName: json['planName'] as String? ?? '—',
        period: json['period'] as String? ?? '—',
        total: _toDouble(json['total'] ?? json['amount']) ?? 0,
        paid: _toDouble(json['paid'] ?? json['paidAmount']) ?? 0,
        balance: _toDouble(json['balance'] ?? json['remaining']) ?? 0,
        status: json['status'] as String? ?? 'aberta',
        dueDate: _toDate(json['dueDate'] ?? json['dueAt']),
      );

  PlatformPayment _mapPayment(Map<String, dynamic> json) => PlatformPayment(
        id: '${json['id']}',
        tenantName: json['tenantName'] as String? ?? '—',
        invoiceId: '${json['invoiceId'] ?? ''}',
        invoiceNumber: json['invoiceNumber'] as String? ?? '—',
        amount: _toDouble(json['amount']) ?? 0,
        method: json['method'] as String? ?? json['paymentMethod'] as String? ?? '—',
        reference: json['reference'] as String? ?? '—',
        status: json['status'] as String? ?? 'pendente',
        confirmedAt: _toDate(json['confirmedAt']),
      );

  double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  DateTime? _toDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse('$value');
  }
}

final platformAdminDataSourceProvider = Provider<PlatformAdminDataSource>((ref) {
  return PlatformAdminDataSource(ref.watch(dioProvider));
});

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
    final branches = await fetchBranches(tenantId, includeInactive: true);
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
        all.addAll(
          invoices.map(
            (invoice) => PlatformInvoice(
              id: invoice.id,
              tenantId: tenant.id,
              number: invoice.number,
              tenantName: tenant.tenantName.isNotEmpty
                  ? tenant.tenantName
                  : tenant.companyName,
              planName: invoice.planName,
              period: invoice.period,
              total: invoice.total,
              paid: invoice.paid,
              balance: invoice.balance,
              status: invoice.status,
              dueDate: invoice.dueDate,
              paidAt: invoice.paidAt,
              branchesUsed: invoice.branchesUsed,
              extraBranches: invoice.extraBranches,
              planMonthlyPrice: invoice.planMonthlyPrice,
              includedBranches: invoice.includedBranches,
              extraBranchPrice: invoice.extraBranchPrice,
              subtotal: invoice.subtotal,
            ),
          ),
        );
      } catch (_) {}
    }
    return all;
  }

  Future<List<PlatformBranchListItem>> fetchAllBranches() async {
    final tenants = await fetchTenants();
    final all = <PlatformBranchListItem>[];
    for (final tenant in tenants) {
      try {
        final branches = await fetchBranches(tenant.id, includeInactive: true);
        for (final branch in branches) {
          all.add(
            PlatformBranchListItem(
              tenantId: tenant.id,
              tenantName: tenant.tenantName,
              companyName: tenant.companyName,
              branch: branch,
            ),
          );
        }
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralTenants,
        data: payload.toJson(),
        options: Options(
          // Provisionamento: BD + migrations + seed estrutural pode demorar vários minutos.
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 5),
        ),
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
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformBranch> createBranch({
    required String tenantId,
    required String name,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.centralTenants}/$tenantId/branches',
        data: {'name': name},
        options: Options(
          // Provisionamento: BD dedicada + migrations + seed + clone de users.
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      final body = ApiEnvelope.unwrapMap(data);
      return _mapBranch(body);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformBranch> deactivateBranch({
    required String tenantId,
    required String branchId,
    String? reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.centralTenants}/$tenantId/branches/$branchId/deactivate',
        data: {
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      final body = ApiEnvelope.unwrapMap(data);
      return _mapBranch({...body, 'active': false});
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformBranch> activateBranch({
    required String tenantId,
    required String branchId,
    String? reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.centralTenants}/$tenantId/branches/$branchId/activate',
        data: {
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      final body = ApiEnvelope.unwrapMap(data);
      return _mapBranch({...body, 'active': true});
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<PlatformBranchHistoryItem>> fetchBranchHistory(
    String tenantId,
  ) async {
    final data = await _getList(
      '${ApiConstants.centralTenants}/$tenantId/subscription/branch-history',
      query: {'limit': '100'},
    );
    return data.map(_mapBranchHistory).toList();
  }

  Future<List<PlatformBranch>> fetchBranches(
    String tenantId, {
    bool includeInactive = true,
  }) async {
    final data = await _getList(
      '${ApiConstants.centralTenants}/$tenantId/branches',
      query: {'includeInactive': includeInactive ? 'true' : 'false'},
    );
    return data.map(_mapBranch).toList();
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
    if (err is String && err.isNotEmpty) return err;
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    return 'Erro na API central.';
  }

  PlatformTenantSummary _mapTenantSummary(Map<String, dynamic> json) {
    final branches = json['branches'];
    final branchCount = branches is List
        ? branches.where((b) => b is Map && (b['active'] as bool? ?? true)).length
        : 0;
    final sub = json['subscription'];
    String? planName;
    double? monthlyValue;
    DateTime? nextBilling;
    if (sub is Map<String, dynamic>) {
      final plan = sub['plan'];
      final planMap = plan is Map<String, dynamic> ? plan : null;
      planName = sub['planName'] as String? ??
          planMap?['name'] as String? ??
          sub['plan']?.toString();
      monthlyValue = _toDouble(
        sub['monthlyPrice'] ?? sub['price'] ?? planMap?['monthlyPrice'],
      );
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
        isHeadOffice: json['isHeadOffice'] as bool? ?? false,
        lastSyncAt: _toDate(json['lastSyncAt']),
        dbName: json['dbName'] as String?,
        connectionStatus: json['connectionStatus'] as String?,
      );

  PlatformBranchHistoryItem _mapBranchHistory(Map<String, dynamic> json) =>
      PlatformBranchHistoryItem(
        id: '${json['id']}',
        action: json['action'] as String? ?? '—',
        effectiveDate:
            _toDate(json['effectiveDate'] ?? json['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0),
        branchId: json['branchId']?.toString(),
        branchCode: json['branchCode'] as String?,
        branchName: json['branchName'] as String?,
        reason: json['reason'] as String?,
        createdByName: json['createdByName'] as String?,
        createdByEmail: json['createdByEmail'] as String?,
      );

  PlatformSubscription _mapSubscription(Map<String, dynamic> json) {
    final plan = json['plan'];
    final planMap = plan is Map<String, dynamic> ? plan : null;
    final next = json['estimatedNextInvoice'];
    final nextMap = next is Map<String, dynamic> ? next : null;
    final breakdown = nextMap?['breakdown'];
    final breakdownMap =
        breakdown is Map<String, dynamic> ? breakdown : null;
    final lastInvoice = json['lastInvoice'];
    final lastMap =
        lastInvoice is Map<String, dynamic> ? lastInvoice : null;
    final pending = json['pendingTrialInvoice'];
    final pendingMap = pending is Map<String, dynamic> ? pending : null;

    final included = json['includedBranches'] as int? ??
        planMap?['includedBranches'] as int? ??
        0;
    final used = json['branchesUsed'] as int? ??
        json['usedBranches'] as int? ??
        json['activeBranches'] as int? ??
        0;
    final active = json['activeBranches'] as int? ?? used;
    final extras = json['extraBranches'] as int? ?? 0;
    final basePrice = _toDouble(
      json['baseMonthlyPrice'] ??
          json['monthlyPrice'] ??
          planMap?['monthlyPrice'],
    );
    final extraPrice = _toDouble(
      json['extraBranchPrice'] ?? planMap?['extraBranchPrice'],
    );
    final estimatedTotal = _toDouble(json['estimatedMonthlyTotal']) ??
        _toDouble(nextMap?['amount']);

    return PlatformSubscription(
      planName: json['planName'] as String? ??
          planMap?['name'] as String? ??
          '—',
      planSlug: json['planSlug'] as String? ?? planMap?['slug'] as String?,
      status: json['status'] as String? ?? 'ativo',
      startDate: _toDate(json['startDate']),
      endDate: _toDate(json['endDate']),
      trialEndsAt: _toDate(json['trialEndsAt']),
      nextBillingAt: _toDate(json['nextBillingAt']),
      lastBillingAt: _toDate(json['lastBillingAt']),
      currentPeriodEnd: _toDate(json['currentPeriodEnd']),
      includedBranches: included,
      usedBranches: used,
      activeBranches: active,
      extraBranches: extras,
      monthlyPrice: basePrice,
      extraBranchPrice: extraPrice,
      estimatedMonthlyTotal: estimatedTotal,
      isEnterprise: json['isEnterprise'] as bool? ??
          planMap?['isEnterprise'] as bool? ??
          false,
      trialDays: json['trialDays'] as int? ?? planMap?['trialDays'] as int?,
      estimatedNextInvoice: nextMap == null
          ? null
          : PlatformEstimatedNextInvoice(
              amount: _toDouble(nextMap['amount']) ?? estimatedTotal ?? 0,
              currency: nextMap['currency'] as String? ?? 'MZN',
              periodStart: _toDate(nextMap['periodStart']),
              periodEnd: _toDate(nextMap['periodEnd']),
              branchesUsed: nextMap['branchesUsed'] as int? ?? used,
              includedBranches:
                  nextMap['includedBranches'] as int? ?? included,
              extraBranches: nextMap['extraBranches'] as int? ?? extras,
              planMonthlyPrice: _toDouble(
                    breakdownMap?['planMonthlyPrice'],
                  ) ??
                  basePrice ??
                  0,
              extraBranchesCharge:
                  _toDouble(breakdownMap?['extraBranchesCharge']) ?? 0,
              extraBranchPrice: _toDouble(
                    breakdownMap?['extraBranchPrice'],
                  ) ??
                  extraPrice ??
                  0,
            ),
      lastInvoiceNumber: lastMap?['number'] as String?,
      lastInvoiceStatus: lastMap?['status'] as String?,
      lastInvoiceAmount: _toDouble(lastMap?['amount']),
      lastInvoiceDueDate: _toDate(lastMap?['dueDate']),
      pendingTrialInvoiceId: pendingMap?['id']?.toString(),
      pendingTrialInvoiceAmount: _toDouble(pendingMap?['amount']),
      pendingTrialInvoiceDueDate: _toDate(pendingMap?['dueDate']),
    );
  }

  PlatformInvoice _mapInvoice(Map<String, dynamic> json, String tenantId) {
    final periodStart = _toDate(json['periodStart']);
    final periodEnd = _toDate(json['periodEnd']);
    final period = json['period'] as String? ??
        (periodStart != null && periodEnd != null
            ? '${periodStart.toIso8601String().substring(0, 10)} a ${periodEnd.toIso8601String().substring(0, 10)}'
            : '—');

    return PlatformInvoice(
      id: '${json['id']}',
      tenantId: tenantId,
      number:
          json['number'] as String? ?? json['invoiceNumber'] as String? ?? '—',
      tenantName: json['tenantName'] as String? ?? tenantId,
      planName: json['planName'] as String? ?? '—',
      period: period,
      total: _toDouble(json['total'] ?? json['amount']) ?? 0,
      paid: _toDouble(json['paid'] ?? json['paidAmount']) ?? 0,
      balance: _toDouble(
            json['balance'] ?? json['remaining'] ?? json['remainingAmount'],
          ) ??
          0,
      status: json['status'] as String? ?? 'pendente',
      dueDate: _toDate(json['dueDate'] ?? json['dueAt']),
      paidAt: _toDate(json['paidAt']),
      branchesUsed: json['branchesUsed'] as int? ??
          json['snapshotTotalBranches'] as int?,
      extraBranches: json['extraBranches'] as int? ??
          json['snapshotExtraBranches'] as int?,
      planMonthlyPrice: _toDouble(json['planMonthlyPrice']),
      includedBranches: json['includedBranches'] as int?,
      extraBranchPrice: _toDouble(json['extraBranchPrice']),
      subtotal: _toDouble(json['subtotal']),
    );
  }

  PlatformPayment _mapPayment(Map<String, dynamic> json) => PlatformPayment(
        id: '${json['id']}',
        tenantName: json['tenantName'] as String? ?? '—',
        invoiceId: '${json['invoiceId'] ?? ''}',
        invoiceNumber: json['invoiceNumber'] as String? ?? '—',
        amount: _toDouble(json['amount']) ?? 0,
        method:
            json['method'] as String? ?? json['paymentMethod'] as String? ?? '—',
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

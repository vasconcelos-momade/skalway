import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../../../../core/utils/api_list_response.dart';
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
      walletBalance: subscription?.walletBalance,
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
    final page = await fetchInvoicesPage(page: 1, pageSize: 100);
    return page.items;
  }

  Future<PaginationResponse<PlatformInvoice>> fetchInvoicesPage({
    int page = 1,
    int pageSize = 20,
    String? q,
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralInvoices,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        },
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: (row) => _mapInvoice(row),
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PaginationResponse<PlatformTenantSummary>> fetchTenantsPage({
    int page = 1,
    int pageSize = 20,
    String? q,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralTenants,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: _mapTenantSummary,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PaginationResponse<PlatformAuditLogEntry>> fetchAuditLogs({
    int page = 1,
    int pageSize = 20,
    String? q,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralAuditLogs,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: PlatformAuditLogEntry.fromJson,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<PlatformBranchListItem>> fetchAllBranches() async {
    final page = await fetchBranchesPage(page: 1, pageSize: 100);
    return page.items;
  }

  Future<PaginationResponse<PlatformBranchListItem>> fetchBranchesPage({
    int page = 1,
    int pageSize = 20,
    String? q,
    bool includeInactive = true,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralBranches,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          'includeInactive': includeInactive ? 'true' : 'false',
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: _mapBranchListItem,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<PlatformPayment>> fetchAllPayments() async {
    final page = await fetchPaymentsPage(page: 1, pageSize: 100);
    return page.items;
  }

  Future<PaginationResponse<PlatformPayment>> fetchPaymentsPage({
    int page = 1,
    int pageSize = 20,
    String? q,
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralPayments,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        },
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: _mapPayment,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
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

  /// Submete e confirma pagamento de fatura (fluxo SuperAdmin).
  Future<void> confirmInvoicePayment({
    required String tenantId,
    required ConfirmInvoicePaymentPayload payload,
  }) async {
    try {
      final submitResponse = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.centralTenants}/$tenantId/payments',
        data: payload.toJson(),
      );
      final submitData = submitResponse.data;
      if (submitData == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (submitData['success'] == false) {
        throw ApiFailure(_errorMessage(submitData));
      }
      final body = ApiEnvelope.unwrapMap(submitData);
      final paymentId = '${body['id'] ?? ''}';
      if (paymentId.isEmpty) {
        throw const ApiFailure('Pagamento criado sem identificador.');
      }
      await confirmPayment(tenantId: tenantId, paymentId: paymentId);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> creditWallet({
    required String tenantId,
    required CreditWalletPayload payload,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.centralTenants}/$tenantId/wallet/credit',
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return ApiEnvelope.unwrapMap(data);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<PlatformPlan>> fetchPlans({bool includeInactive = true}) async {
    final page = await fetchPlansPage(
      page: 1,
      pageSize: 100,
      includeInactive: includeInactive,
    );
    return page.items;
  }

  Future<PaginationResponse<PlatformPlan>> fetchPlansPage({
    int page = 1,
    int pageSize = 20,
    String? q,
    bool includeInactive = true,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralPlans,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          'includeInactive': includeInactive ? 'true' : 'false',
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: _mapPlan,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformPlan> createPlan(PlatformPlanPayload payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralPlans,
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapPlan(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformPlan> updatePlan({
    required String planId,
    required PlatformPlanPayload payload,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.centralPlan(planId),
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapPlan(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformPlan> deactivatePlan(String planId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralPlanDeactivate(planId),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapPlan(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformPlan> setPlanActive({
    required String planId,
    required bool active,
  }) async {
    if (!active) return deactivatePlan(planId);
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.centralPlan(planId),
        data: {'active': true},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapPlan(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<PlatformUser>> fetchUsers({
    bool includeInactive = true,
    String role = 'superadmin',
  }) async {
    final page = await fetchUsersPage(
      page: 1,
      pageSize: 100,
      includeInactive: includeInactive,
      role: role,
    );
    return page.items;
  }

  Future<PaginationResponse<PlatformUser>> fetchUsersPage({
    int page = 1,
    int pageSize = 20,
    String? q,
    bool includeInactive = true,
    String role = 'superadmin',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.centralUsers,
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
          'includeInactive': includeInactive ? 'true' : 'false',
          'role': role,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: _mapUser,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformUser> createUser(PlatformUserPayload payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralUsers,
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapUser(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformUser> updateUser({
    required String userId,
    required PlatformUserPayload payload,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.centralUser(userId),
        data: payload.toJson(includePassword: payload.password != null),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapUser(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformUser> deactivateUser(String userId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralUserDeactivate(userId),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapUser(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformUser> setUserActive({
    required String userId,
    required bool active,
  }) async {
    if (!active) return deactivateUser(userId);
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.centralUser(userId),
        data: {'active': true},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapUser(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformUser> resetUserPassword({
    required String userId,
    required String password,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.centralUser(userId),
        data: {'password': password},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapUser(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PlatformCentralSettings> fetchCentralSettings() async {
    final data = await _getMap(ApiConstants.centralSettings);
    return _mapCentralSettings(data);
  }

  Future<PlatformCentralSettings> updateCentralSettings(
    PlatformCentralSettingsPayload payload,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.centralSettings,
        data: payload.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida.');
      }
      if (data['success'] == false) {
        throw ApiFailure(_errorMessage(data));
      }
      return _mapCentralSettings(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
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

  PlatformBranchListItem _mapBranchListItem(Map<String, dynamic> json) {
    final branchRaw = json['branch'];
    final branchMap = branchRaw is Map<String, dynamic>
        ? branchRaw
        : json;
    return PlatformBranchListItem(
      tenantId: json['tenantId']?.toString() ?? '',
      tenantName: json['tenantName'] as String? ?? '—',
      companyName: json['companyName'] as String? ?? '',
      branch: _mapBranch(branchMap),
    );
  }

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
      walletBalance: _toDouble(json['walletBalance']),
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

  PlatformInvoice _mapInvoice(Map<String, dynamic> json, [String? tenantId]) {
    final periodStart = _toDate(json['periodStart']);
    final periodEnd = _toDate(json['periodEnd']);
    final period = json['period'] as String? ??
        (periodStart != null && periodEnd != null
            ? '${periodStart.toIso8601String().substring(0, 10)} a ${periodEnd.toIso8601String().substring(0, 10)}'
            : '—');
    final discount = _toDouble(json['discount']) ?? 0;
    final amount = _toDouble(json['amount'] ?? json['total']) ?? 0;
    final payable = _toDouble(json['payableAmount']);

    return PlatformInvoice(
      id: '${json['id']}',
      tenantId: tenantId ??
          json['tenantId']?.toString() ??
          '',
      number:
          json['number'] as String? ?? json['invoiceNumber'] as String? ?? '—',
      tenantName: json['tenantName'] as String? ?? tenantId ?? '—',
      companyName: json['companyName'] as String?,
      planName: json['planName'] as String? ?? '—',
      period: period,
      total: amount,
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
      extrasAmount: _toDouble(json['extrasAmount']),
      subtotal: _toDouble(json['subtotal']),
      discount: discount,
      payableAmount: payable,
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

  PlatformPlan _mapPlan(Map<String, dynamic> json) => PlatformPlan(
        id: '${json['id']}',
        name: json['name'] as String? ?? '—',
        slug: json['slug'] as String? ?? '',
        monthlyPrice: _toDouble(json['monthlyPrice']) ?? 0,
        includedBranches: json['includedBranches'] as int? ?? 1,
        extraBranchPrice: _toDouble(json['extraBranchPrice']) ?? 0,
        billingIntervalMonths: json['billingIntervalMonths'] as int? ?? 1,
        trialDays: json['trialDays'] as int? ?? 0,
        active: json['active'] as bool? ?? true,
        isEnterprise: json['isEnterprise'] as bool? ?? false,
        createdAt: _toDate(json['createdAt']),
        updatedAt: _toDate(json['updatedAt']),
      );

  PlatformUser _mapUser(Map<String, dynamic> json) => PlatformUser(
        id: '${json['id']}',
        name: json['name'] as String? ?? '—',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'superadmin',
        active: json['active'] as bool? ?? true,
        lastLoginAt: _toDate(json['lastLoginAt']),
        createdAt: _toDate(json['createdAt']),
        updatedAt: _toDate(json['updatedAt']),
      );

  PlatformCentralSettings _mapCentralSettings(Map<String, dynamic> json) =>
      PlatformCentralSettings(
        id: '${json['id']}',
        companyName: json['companyName'] as String? ?? '',
        companyNuit: json['companyNuit'] as String? ?? '',
        companyEmail: json['companyEmail'] as String? ?? '',
        companyPhone: json['companyPhone'] as String? ?? '',
        companyAddress: json['companyAddress'] as String? ?? '',
        companyCity: json['companyCity'] as String?,
        companyProvince: json['companyProvince'] as String?,
        companyCountry: json['companyCountry'] as String? ?? 'MZ',
        companyLogo: json['companyLogo'] as String?,
        mpesaAccountName: json['mpesaAccountName'] as String?,
        mpesaAccountNumber: json['mpesaAccountNumber'] as String?,
        emolaAccountName: json['emolaAccountName'] as String?,
        emolaAccountNumber: json['emolaAccountNumber'] as String?,
        bankName: json['bankName'] as String?,
        bankAccountName: json['bankAccountName'] as String?,
        bankAccountNumber: json['bankAccountNumber'] as String?,
        bankAccountNib: json['bankAccountNib'] as String?,
        bankAccountSwift: json['bankAccountSwift'] as String?,
        bankTransferInstructions: json['bankTransferInstructions'] as String?,
        invoiceFooter: json['invoiceFooter'] as String?,
        receiptFooter: json['receiptFooter'] as String?,
        defaultMessage: json['defaultMessage'] as String?,
        active: json['active'] as bool? ?? true,
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

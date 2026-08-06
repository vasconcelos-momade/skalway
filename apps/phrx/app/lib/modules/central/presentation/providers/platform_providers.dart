import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/errors/api_failure.dart';
import '../../data/datasources/platform_admin_datasource.dart';
import '../../domain/entities/platform_entities.dart';
import '../../../../platform/files/platform_file_delivery.dart';

class PlatformDashboardNotifier extends AsyncNotifier<PlatformDashboardStats> {
  @override
  Future<PlatformDashboardStats> build() {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<PlatformDashboardStats> _load() {
    return ref.read(platformAdminDataSourceProvider).fetchDashboardStats();
  }
}

final platformDashboardProvider =
    AsyncNotifierProvider<PlatformDashboardNotifier, PlatformDashboardStats>(
  PlatformDashboardNotifier.new,
);

class PlatformTenantsNotifier
    extends AsyncNotifier<PaginationResponse<PlatformTenantSummary>> {
  String _search = '';
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;

  String get search => _search;
  int get page => _page;
  int get pageSize => _pageSize;

  @override
  Future<PaginationResponse<PlatformTenantSummary>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setSearch(String value) {
    _search = value.trim();
    _page = 1;
    ref.invalidateSelf();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> setPageSize(int size) async {
    _pageSize = size.clamp(1, 100);
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<PaginationResponse<PlatformTenantSummary>> _load() {
    return ref.read(platformAdminDataSourceProvider).fetchTenantsPage(
          page: _page,
          pageSize: _pageSize,
          q: _search.isEmpty ? null : _search,
        );
  }
}

final platformTenantsProvider = AsyncNotifierProvider<PlatformTenantsNotifier,
    PaginationResponse<PlatformTenantSummary>>(
  PlatformTenantsNotifier.new,
);

final platformTenantDetailProvider = FutureProvider.autoDispose
    .family<PlatformTenantDetail, String>((ref, tenantId) {
  return ref.read(platformAdminDataSourceProvider).fetchTenantDetail(tenantId);
});

class PlatformInvoicesNotifier
    extends AsyncNotifier<PaginationResponse<PlatformInvoice>> {
  String _search = '';
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;

  String get search => _search;
  int get page => _page;
  int get pageSize => _pageSize;

  @override
  Future<PaginationResponse<PlatformInvoice>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setSearch(String value) {
    _search = value.trim();
    _page = 1;
    ref.invalidateSelf();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> setPageSize(int size) async {
    _pageSize = size.clamp(1, 100);
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<PaginationResponse<PlatformInvoice>> _load() {
    return ref.read(platformAdminDataSourceProvider).fetchInvoicesPage(
          page: _page,
          pageSize: _pageSize,
          q: _search.isEmpty ? null : _search,
        );
  }
}

final platformInvoicesProvider = AsyncNotifierProvider<PlatformInvoicesNotifier,
    PaginationResponse<PlatformInvoice>>(
  PlatformInvoicesNotifier.new,
);

enum PlatformAuditViewState { loading, loaded, empty, error, updating }

class PlatformAuditListState {
  const PlatformAuditListState({
    this.items = const [],
    this.page = 1,
    this.pageSize = PaginationDefaults.pageSize,
    this.search = '',
    this.viewState = PlatformAuditViewState.loading,
    this.errorMessage,
    this.hasMore = false,
    this.totalCount,
  });

  final List<PlatformAuditLogEntry> items;
  final int page;
  final int pageSize;
  final String search;
  final PlatformAuditViewState viewState;
  final String? errorMessage;
  final bool hasMore;
  final int? totalCount;

  bool get isBusy =>
      viewState == PlatformAuditViewState.loading ||
      viewState == PlatformAuditViewState.updating;

  PlatformAuditListState copyWith({
    List<PlatformAuditLogEntry>? items,
    int? page,
    int? pageSize,
    String? search,
    PlatformAuditViewState? viewState,
    String? errorMessage,
    bool? hasMore,
    int? totalCount,
    bool clearError = false,
  }) {
    return PlatformAuditListState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class PlatformAuditLogsController extends Notifier<PlatformAuditListState> {
  @override
  PlatformAuditListState build() {
    Future.microtask(load);
    return const PlatformAuditListState();
  }

  Future<void> load() => goToPage(1);

  Future<void> refresh() => goToPage(state.page);

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value.trim(), page: 1);
    await goToPage(1);
  }

  Future<void> goToPage(int page) async {
    final target = page < 1 ? 1 : page;
    state = state.copyWith(
      viewState: state.items.isEmpty
          ? PlatformAuditViewState.loading
          : PlatformAuditViewState.updating,
      page: target,
      clearError: true,
    );
    try {
      final response =
          await ref.read(platformAdminDataSourceProvider).fetchAuditLogs(
                page: target,
                pageSize: state.pageSize,
                q: state.search.isEmpty ? null : state.search,
              );
      state = state.copyWith(
        items: response.items,
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        viewState: response.items.isEmpty
            ? PlatformAuditViewState.empty
            : PlatformAuditViewState.loaded,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        viewState: PlatformAuditViewState.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        viewState: PlatformAuditViewState.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setPageSize(int size) async {
    state = state.copyWith(pageSize: size.clamp(1, 100), page: 1);
    await goToPage(1);
  }
}

final platformAuditLogsProvider =
    NotifierProvider.autoDispose<PlatformAuditLogsController, PlatformAuditListState>(
  PlatformAuditLogsController.new,
);

class PlatformBranchesNotifier
    extends AsyncNotifier<PaginationResponse<PlatformBranchListItem>> {
  String _search = '';
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;

  String get search => _search;
  int get page => _page;
  int get pageSize => _pageSize;

  @override
  Future<PaginationResponse<PlatformBranchListItem>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setSearch(String value) {
    _search = value.trim();
    _page = 1;
    ref.invalidateSelf();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> setPageSize(int size) async {
    _pageSize = size.clamp(1, 100);
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<PaginationResponse<PlatformBranchListItem>> _load() {
    return ref.read(platformAdminDataSourceProvider).fetchBranchesPage(
          page: _page,
          pageSize: _pageSize,
          q: _search.isEmpty ? null : _search,
        );
  }
}

final platformBranchesProvider = AsyncNotifierProvider<PlatformBranchesNotifier,
    PaginationResponse<PlatformBranchListItem>>(
  PlatformBranchesNotifier.new,
);

class PlatformPaymentsNotifier
    extends AsyncNotifier<PaginationResponse<PlatformPayment>> {
  String _search = '';
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;

  String get search => _search;
  int get page => _page;
  int get pageSize => _pageSize;

  @override
  Future<PaginationResponse<PlatformPayment>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setSearch(String value) {
    _search = value.trim();
    _page = 1;
    ref.invalidateSelf();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> setPageSize(int size) async {
    _pageSize = size.clamp(1, 100);
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<PaginationResponse<PlatformPayment>> _load() {
    return ref.read(platformAdminDataSourceProvider).fetchPaymentsPage(
          page: _page,
          pageSize: _pageSize,
          q: _search.isEmpty ? null : _search,
        );
  }
}

final platformPaymentsProvider = AsyncNotifierProvider<PlatformPaymentsNotifier,
    PaginationResponse<PlatformPayment>>(
  PlatformPaymentsNotifier.new,
);
final platformTenantInvoicesProvider = FutureProvider.autoDispose
    .family<List<PlatformInvoice>, String>((ref, tenantId) {
  return ref.read(platformAdminDataSourceProvider).fetchInvoices(tenantId);
});

final platformTenantPaymentsProvider = FutureProvider.autoDispose
    .family<List<PlatformPayment>, String>((ref, tenantId) {
  return ref.read(platformAdminDataSourceProvider).fetchPayments(tenantId);
});

final platformTenantBranchHistoryProvider = FutureProvider.autoDispose
    .family<List<PlatformBranchHistoryItem>, String>((ref, tenantId) {
  return ref.read(platformAdminDataSourceProvider).fetchBranchHistory(tenantId);
});

/// Invalida providers de billing do tenant (Ref ou WidgetRef).
void invalidateTenantBilling(dynamic ref, String tenantId) {
  ref.invalidate(platformTenantDetailProvider(tenantId));
  ref.invalidate(platformTenantInvoicesProvider(tenantId));
  ref.invalidate(platformTenantPaymentsProvider(tenantId));
  ref.invalidate(platformTenantBranchHistoryProvider(tenantId));
  ref.invalidate(platformTenantsProvider);
  ref.invalidate(platformDashboardProvider);
  ref.invalidate(platformInvoicesProvider);
  ref.invalidate(platformPaymentsProvider);
  ref.invalidate(platformBranchesProvider);
}

void invalidatePlatformCatalog(dynamic ref) {
  ref.invalidate(platformPlansProvider);
  ref.invalidate(platformUsersProvider);
  ref.invalidate(platformDashboardProvider);
  ref.invalidate(platformTenantsProvider);
}

final platformPlansProvider = AsyncNotifierProvider<PlatformPlansNotifier,
    PaginationResponse<PlatformPlan>>(
  PlatformPlansNotifier.new,
);

class PlatformPlansNotifier
    extends AsyncNotifier<PaginationResponse<PlatformPlan>> {
  String _search = '';
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;

  String get search => _search;
  int get page => _page;
  int get pageSize => _pageSize;

  @override
  Future<PaginationResponse<PlatformPlan>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setSearch(String value) {
    _search = value.trim();
    _page = 1;
    ref.invalidateSelf();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> setPageSize(int size) async {
    _pageSize = size.clamp(1, 100);
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<PaginationResponse<PlatformPlan>> _load() {
    return ref.read(platformAdminDataSourceProvider).fetchPlansPage(
          page: _page,
          pageSize: _pageSize,
          q: _search.isEmpty ? null : _search,
        );
  }
}

final platformCentralSettingsProvider =
    FutureProvider.autoDispose<PlatformCentralSettings>((ref) {
  return ref.read(platformAdminDataSourceProvider).fetchCentralSettings();
});

class PlatformUsersNotifier
    extends AsyncNotifier<PaginationResponse<PlatformUser>> {
  String _search = '';
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;

  String get search => _search;
  int get page => _page;
  int get pageSize => _pageSize;

  @override
  Future<PaginationResponse<PlatformUser>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setSearch(String value) {
    _search = value.trim();
    _page = 1;
    ref.invalidateSelf();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> setPageSize(int size) async {
    _pageSize = size.clamp(1, 100);
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<PaginationResponse<PlatformUser>> _load() {
    return ref.read(platformAdminDataSourceProvider).fetchUsersPage(
          page: _page,
          pageSize: _pageSize,
          q: _search.isEmpty ? null : _search,
        );
  }
}

final platformUsersProvider = AsyncNotifierProvider<PlatformUsersNotifier,
    PaginationResponse<PlatformUser>>(
  PlatformUsersNotifier.new,
);

class PlatformBillingActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<RegisterTenantResult> registerTenant(RegisterTenantPayload payload) async {
    state = true;
    try {
      final result =
          await ref.read(platformAdminDataSourceProvider).registerTenant(payload);
      ref.invalidate(platformTenantsProvider);
      ref.invalidate(platformDashboardProvider);
      return result;
    } finally {
      state = false;
    }
  }

  Future<PlatformBranch> createBranch({
    required String tenantId,
    required String name,
  }) async {
    state = true;
    try {
      final branch = await ref.read(platformAdminDataSourceProvider).createBranch(
            tenantId: tenantId,
            name: name,
          );
      invalidateTenantBilling(ref, tenantId);
      return branch;
    } finally {
      state = false;
    }
  }

  Future<PlatformBranch> deactivateBranch({
    required String tenantId,
    required String branchId,
    String? reason,
  }) async {
    state = true;
    try {
      final branch =
          await ref.read(platformAdminDataSourceProvider).deactivateBranch(
                tenantId: tenantId,
                branchId: branchId,
                reason: reason,
              );
      invalidateTenantBilling(ref, tenantId);
      return branch;
    } finally {
      state = false;
    }
  }

  Future<PlatformBranch> activateBranch({
    required String tenantId,
    required String branchId,
    String? reason,
  }) async {
    state = true;
    try {
      final branch =
          await ref.read(platformAdminDataSourceProvider).activateBranch(
                tenantId: tenantId,
                branchId: branchId,
                reason: reason,
              );
      invalidateTenantBilling(ref, tenantId);
      return branch;
    } finally {
      state = false;
    }
  }

  Future<void> confirmPayment({
    required String tenantId,
    required String paymentId,
  }) async {
    state = true;
    try {
      await ref.read(platformAdminDataSourceProvider).confirmPayment(
            tenantId: tenantId,
            paymentId: paymentId,
          );
      invalidateTenantBilling(ref, tenantId);
    } finally {
      state = false;
    }
  }

  Future<void> confirmInvoicePayment({
    required String tenantId,
    required ConfirmInvoicePaymentPayload payload,
  }) async {
    state = true;
    try {
      await ref.read(platformAdminDataSourceProvider).confirmInvoicePayment(
            tenantId: tenantId,
            payload: payload,
          );
      invalidateTenantBilling(ref, tenantId);
    } finally {
      state = false;
    }
  }

  Future<void> creditWallet({
    required String tenantId,
    required CreditWalletPayload payload,
  }) async {
    state = true;
    try {
      await ref.read(platformAdminDataSourceProvider).creditWallet(
            tenantId: tenantId,
            payload: payload,
          );
      invalidateTenantBilling(ref, tenantId);
    } finally {
      state = false;
    }
  }

  Future<PlatformPlan> createPlan(PlatformPlanPayload payload) async {
    state = true;
    try {
      final plan =
          await ref.read(platformAdminDataSourceProvider).createPlan(payload);
      invalidatePlatformCatalog(ref);
      return plan;
    } finally {
      state = false;
    }
  }

  Future<PlatformPlan> updatePlan({
    required String planId,
    required PlatformPlanPayload payload,
  }) async {
    state = true;
    try {
      final plan = await ref.read(platformAdminDataSourceProvider).updatePlan(
            planId: planId,
            payload: payload,
          );
      invalidatePlatformCatalog(ref);
      return plan;
    } finally {
      state = false;
    }
  }

  Future<PlatformPlan> setPlanActive({
    required String planId,
    required bool active,
  }) async {
    state = true;
    try {
      final plan = await ref.read(platformAdminDataSourceProvider).setPlanActive(
            planId: planId,
            active: active,
          );
      invalidatePlatformCatalog(ref);
      return plan;
    } finally {
      state = false;
    }
  }

  Future<PlatformUser> createUser(PlatformUserPayload payload) async {
    state = true;
    try {
      final user =
          await ref.read(platformAdminDataSourceProvider).createUser(payload);
      ref.invalidate(platformUsersProvider);
      return user;
    } finally {
      state = false;
    }
  }

  Future<PlatformUser> updateUser({
    required String userId,
    required PlatformUserPayload payload,
  }) async {
    state = true;
    try {
      final user = await ref.read(platformAdminDataSourceProvider).updateUser(
            userId: userId,
            payload: payload,
          );
      ref.invalidate(platformUsersProvider);
      return user;
    } finally {
      state = false;
    }
  }

  Future<PlatformUser> setUserActive({
    required String userId,
    required bool active,
  }) async {
    state = true;
    try {
      final user = await ref.read(platformAdminDataSourceProvider).setUserActive(
            userId: userId,
            active: active,
          );
      ref.invalidate(platformUsersProvider);
      return user;
    } finally {
      state = false;
    }
  }

  Future<PlatformUser> resetUserPassword({
    required String userId,
    required String password,
  }) async {
    state = true;
    try {
      final user =
          await ref.read(platformAdminDataSourceProvider).resetUserPassword(
                userId: userId,
                password: password,
              );
      ref.invalidate(platformUsersProvider);
      return user;
    } finally {
      state = false;
    }
  }

  Future<PlatformCentralSettings> updateCentralSettings(
    PlatformCentralSettingsPayload payload,
  ) async {
    state = true;
    try {
      final settings = await ref
          .read(platformAdminDataSourceProvider)
          .updateCentralSettings(payload);
      ref.invalidate(platformCentralSettingsProvider);
      return settings;
    } finally {
      state = false;
    }
  }

  Future<void> downloadInvoicePdf({
    required String tenantId,
    required String invoiceId,
    required String fileName,
  }) async {
    state = true;
    try {
      final bytes = await ref.read(platformAdminDataSourceProvider).downloadInvoicePdf(
            tenantId: tenantId,
            invoiceId: invoiceId,
          );
      await PlatformFileDelivery.openBytes(
        bytes: bytes,
        fileName: fileName,
        contentType: 'application/pdf',
      );
    } finally {
      state = false;
    }
  }
}

final platformBillingActionsProvider =
    NotifierProvider<PlatformBillingActionsNotifier, bool>(
  PlatformBillingActionsNotifier.new,
);

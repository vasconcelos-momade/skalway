import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class PlatformTenantsNotifier extends AsyncNotifier<List<PlatformTenantSummary>> {
  String _search = '';

  String get search => _search;

  @override
  Future<List<PlatformTenantSummary>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void setSearch(String value) {
    _search = value.trim().toLowerCase();
    ref.invalidateSelf();
  }

  Future<List<PlatformTenantSummary>> _load() async {
    final all = await ref.read(platformAdminDataSourceProvider).fetchTenants();
    if (_search.isEmpty) return all;
    return all
        .where(
          (t) =>
              t.companyName.toLowerCase().contains(_search) ||
              t.tenantName.toLowerCase().contains(_search),
        )
        .toList();
  }
}

final platformTenantsProvider =
    AsyncNotifierProvider<PlatformTenantsNotifier, List<PlatformTenantSummary>>(
  PlatformTenantsNotifier.new,
);

final platformTenantDetailProvider = FutureProvider.autoDispose
    .family<PlatformTenantDetail, String>((ref, tenantId) {
  return ref.read(platformAdminDataSourceProvider).fetchTenantDetail(tenantId);
});

final platformInvoicesProvider =
    FutureProvider.autoDispose<List<PlatformInvoice>>((ref) {
  return ref.read(platformAdminDataSourceProvider).fetchAllInvoices();
});

final platformBranchesProvider =
    FutureProvider.autoDispose<List<PlatformBranchListItem>>((ref) {
  return ref.read(platformAdminDataSourceProvider).fetchAllBranches();
});

final platformPaymentsProvider =
    FutureProvider.autoDispose<List<PlatformPayment>>((ref) {
  return ref.read(platformAdminDataSourceProvider).fetchAllPayments();
});

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

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

class PlatformBillingActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> registerTenant(RegisterTenantPayload payload) async {
    state = true;
    try {
      await ref.read(platformAdminDataSourceProvider).registerTenant(payload);
      ref.invalidate(platformTenantsProvider);
      ref.invalidate(platformDashboardProvider);
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
      ref.invalidate(platformTenantPaymentsProvider(tenantId));
      ref.invalidate(platformTenantInvoicesProvider(tenantId));
      ref.invalidate(platformTenantDetailProvider(tenantId));
      ref.invalidate(platformPaymentsProvider);
      ref.invalidate(platformDashboardProvider);
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

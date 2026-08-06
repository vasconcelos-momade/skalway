import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phrx/app/app.dart';
import 'package:phrx/app/providers/app_theme_mode_provider.dart';
import 'package:phrx/app/providers/auth_session_notifier.dart';
import 'package:phrx/app/providers/connection_notifier.dart';
import 'package:phrx/app/providers/session_access_notifier.dart';
import 'package:phrx/app/router/go_app_router.dart';
import 'package:phrx/app/router/routes.dart';
import 'package:phrx/modules/admin/users/domain/entities/user_entities.dart';
import 'package:phrx/modules/auth/domain/entities/auth_session.dart';
import 'package:phrx/modules/auth/domain/entities/auth_user.dart';
import 'package:phrx/modules/auth/domain/entities/branch_access.dart';
import 'package:phrx/modules/auth/domain/entities/tenant_access.dart';
import 'package:phrx/modules/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:phrx/modules/dashboard/domain/dashboard_query.dart';

import 'package:phrx/modules/pharmacy/categories/presentation/providers/category_provider.dart';
import 'package:phrx/modules/pharmacy/categories/presentation/providers/category_stats_provider.dart';
import 'package:phrx/modules/pharmacy/products/presentation/providers/product_provider.dart';
import 'package:phrx/modules/stock/presentation/providers/fornecedor_provider.dart';

import 'helpers/test_providers.dart';

class _IdleMasterProductList extends MasterProductListController {
  @override
  MasterProductListState build() {
    return const MasterProductListState(isInitialized: true);
  }
}

AuthSessionState _authenticatedState() {
  const tenant = TenantAccess(
    id: '1',
    tenantKey: 'demo',
    tenantName: 'Demo',
    branches: [
      BranchAccess(id: '1', code: 'HQ', name: 'Matriz'),
    ],
  );
  return AuthSessionState(
    session: AuthSession(
      accessToken: 'test-token',
      user: AuthUser(
        id: '1',
        name: 'Test',
        email: 'test@demo.com',
        role: 'admin',
      ),
      tenants: [tenant],
      tenantId: '1',
      branchId: '1',
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    prefs = await initTestSharedPreferences();
  });

  testWidgets('Login mostra formulário', (WidgetTester tester) async {
    await tester.pumpWidget(testLoginApp(prefs));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pharma ERP'), findsWidgets);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
  });

  testWidgets('Navegação para produtos com sessão mock', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authSessionProvider.overrideWith(_MockAuthSessionNotifier.new),
        connectionNotifierProvider.overrideWith(IdleConnectionNotifier.new),
        sessionAccessProvider.overrideWith(_LoadedSessionAccessNotifier.new),
        dashboardRemoteDataSourceProvider.overrideWithValue(_FakeDashboardRemoteDataSource()),
        masterProductListProvider.overrideWith(_IdleMasterProductList.new),
        activeCategoriesProvider.overrideWith((ref) async => const []),
        supplierListProvider.overrideWith((ref) async => const []),
        categoryStatsProvider.overrideWith((ref) async => const {}),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PharmaErpApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(AppRoutePaths.products);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Catálogo master com stock, lotes, validades'),
      findsOneWidget,
    );
    expect(find.text('Novo produto'), findsOneWidget);
  });
}

class _MockAuthSessionNotifier extends AuthSessionNotifier {
  @override
  AuthSessionState build() => _authenticatedState();
}

class _LoadedSessionAccessNotifier extends SessionAccessNotifier {
  @override
  SessionAccessState build() {
    return const SessionAccessState(
      permissions: UserEffectivePermissions(userId: '1', role: 'admin'),
      viewState: SessionAccessViewState.loaded,
    );
  }
}

class _FakeDashboardRemoteDataSource extends DashboardRemoteDataSource {
  _FakeDashboardRemoteDataSource() : super(Dio());

  static const _emptyDashboard = {
    'kpis': <String, dynamic>{},
    'tables': <String, dynamic>{},
    'charts': <String, dynamic>{},
  };

  static const _emptyTable = {
    'items': <Map<String, dynamic>>[],
    'page': 1,
    'pageSize': 0,
    'hasMore': false,
    'hasPrevious': false,
    'totalCount': 0,
    'totalPages': 1,
  };

  @override
  Future<Map<String, dynamic>> executiveDashboard(DashboardQuery query) async =>
      _emptyDashboard;

  @override
  Future<Map<String, dynamic>> financeDashboard(DashboardQuery query) async =>
      _emptyDashboard;

  @override
  Future<Map<String, dynamic>> pharmacyDashboard(DashboardQuery query) async =>
      _emptyDashboard;

  @override
  Future<Map<String, dynamic>> stockDashboard(DashboardQuery query) async =>
      _emptyDashboard;

  @override
  Future<Map<String, dynamic>> executiveDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async =>
      _emptyTable;

  @override
  Future<Map<String, dynamic>> financeDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async =>
      _emptyTable;

  @override
  Future<Map<String, dynamic>> pharmacyDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async =>
      _emptyTable;

  @override
  Future<Map<String, dynamic>> stockDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async =>
      _emptyTable;
}

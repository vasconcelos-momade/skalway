import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/dashboard_query.dart';
import '../../../pharmacy/categories/domain/entities/category.dart';
import '../../../pharmacy/categories/presentation/providers/category_provider.dart';
import '../../../pharmacy/products/data/repositories/product_repository_impl.dart';
import '../../../pharmacy/products/domain/entities/product.dart';

final executiveDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).executiveDashboard(query);
});

final financeDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).financeDashboard(query);
});

final pharmacyDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).pharmacyDashboard(query);
});

final stockDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).stockDashboard(query);
});

/// Invalida KPIs executivos e financeiros (ex.: após movimentos de fluxo de caixa).
void invalidateExecutiveAndFinanceDashboards(Ref ref) {
  ref.invalidate(executiveDashboardProvider);
  ref.invalidate(financeDashboardProvider);
}

/// Variante para [WidgetRef] (páginas Consumer).
void invalidateExecutiveAndFinanceDashboardsFrom(WidgetRef ref) {
  ref.invalidate(executiveDashboardProvider);
  ref.invalidate(financeDashboardProvider);
}

const _defaultExecutiveQuery = DashboardQuery();

/// Contagem operacional para o indicador de alertas no shell (dados reais do dashboard executivo).
final operationalAlertsCountProvider = Provider<int>((ref) {
  final async = ref.watch(executiveDashboardProvider(_defaultExecutiveQuery));
  return async.when(
    data: (data) {
      final kpis = data['kpis'];
      if (kpis is! Map) return 0;
      final criticos = (kpis['produtosCriticos'] as num?)?.toInt() ?? 0;
      final expirados = (kpis['lotesExpirados'] as num?)?.toInt() ?? 0;
      final proximos = (kpis['produtosProximosValidade'] as num?)?.toInt() ?? 0;
      return criticos + expirados + proximos;
    },
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final dashboardFilterCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  return ref.watch(activeCategoriesProvider.future);
});

final dashboardFilterProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final response = await repository.searchMasterProducts(
    page: 1,
    pageSize: 100,
    sortBy: 'nome',
    sortOrder: 'asc',
  );
  return response.items.where((product) => product.ativo).toList(growable: false);
});

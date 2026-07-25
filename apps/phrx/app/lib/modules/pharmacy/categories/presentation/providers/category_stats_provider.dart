import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/category_remote_datasource.dart';

final categoryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(categoryRemoteDataSourceProvider).stats();
});

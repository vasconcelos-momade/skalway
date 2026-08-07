import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/branch_settings_remote_datasource.dart';
import '../../data/models/branch_settings_model.dart';

final branchSettingsProvider =
    AsyncNotifierProvider<BranchSettingsNotifier, BranchSettingsSnapshot>(
  BranchSettingsNotifier.new,
);

class BranchSettingsNotifier extends AsyncNotifier<BranchSettingsSnapshot> {
  @override
  Future<BranchSettingsSnapshot> build() {
    return ref.read(branchSettingsRemoteDataSourceProvider).getActive();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(branchSettingsRemoteDataSourceProvider).getActive(),
    );
  }

  Future<BranchSettingsSnapshot> save(Map<String, dynamic> settings) async {
    final updated =
        await ref.read(branchSettingsRemoteDataSourceProvider).update(settings);
    state = AsyncData(updated);
    return updated;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cache leve de UI (labels, flags de ecrã, última rota visitada).
class UiCacheNotifier extends Notifier<Map<String, Object?>> {
  @override
  Map<String, Object?> build() => {};

  T? get<T>(String key) => state[key] as T?;

  void set<T>(String key, T value) {
    state = {...state, key: value};
  }

  void remove(String key) {
    final next = Map<String, Object?>.from(state)..remove(key);
    state = next;
  }

  void clear() => state = {};
}

final uiCacheProvider =
    NotifierProvider<UiCacheNotifier, Map<String, Object?>>(UiCacheNotifier.new);

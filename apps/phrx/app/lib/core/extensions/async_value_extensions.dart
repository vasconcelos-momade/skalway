import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueGetters<T> on AsyncValue<T> {
  /// Valor quando [AsyncData]; null em loading ou erro.
  T? get valueOrNull => switch (this) {
        AsyncData(:final value) => value,
        _ => null,
      };
}

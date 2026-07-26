import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/connection_notifier.dart';
import '../../config/env.dart';
import 'connection_mode.dart';

/// Resolve o URL base activo (local com recurso à nuvem via [ConnectionNotifier]).
abstract final class EndpointResolver {
  EndpointResolver._();

  static String urlForMode(ConnectionMode mode) {
    return mode == ConnectionMode.cloud ? Env.apiBaseUrlCloud : Env.apiBaseUrlLocal;
  }
}

final activeBaseUrlProvider = Provider<String>((ref) {
  return ref.watch(connectionNotifierProvider).activeBaseUrl;
});

import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phrx/app/app.dart';
import 'package:phrx/app/providers/app_theme_mode_provider.dart';
import 'package:phrx/app/providers/auth_session_notifier.dart';
import 'package:phrx/app/providers/connection_notifier.dart';
import 'package:phrx/core/network/connectivity/connection_status.dart';

/// Evita bootstrap async (secure storage) e animação infinita no login durante testes.
class IdleAuthSessionNotifier extends AuthSessionNotifier {
  @override
  AuthSessionState build() => AuthSessionState.initial;
}

class IdleConnectionNotifier extends ConnectionNotifier {
  @override
  ConnectionState build() {
    return ConnectionState(status: ConnectionStatus.online);
  }
}

Future<SharedPreferences> initTestSharedPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

/// App pronta para testes de ecrã de login (sem bootstrapping).
Widget testLoginApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authSessionProvider.overrideWith(IdleAuthSessionNotifier.new),
      connectionNotifierProvider.overrideWith(IdleConnectionNotifier.new),
    ],
    child: const PharmaErpApp(),
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/auth_session_notifier.dart';
import '../../app/router/go_app_router.dart';
import '../../app/router/routes.dart';
import 'desktop_window.dart';

/// Fechar desktop:
/// - autenticado → logout + ir para login (app continua aberta);
/// - não autenticado → fechar a aplicação.
Future<void> handleDesktopCloseRequest(WidgetRef ref) async {
  if (!supportsDesktopWindowControls) return;

  final authenticated = ref.read(authSessionProvider).isAuthenticated;
  if (authenticated) {
    await ref.read(authSessionProvider.notifier).signOut();
    ref.read(goRouterProvider).go(AppRoutePaths.login);
    return;
  }

  await closeDesktopWindow();
}

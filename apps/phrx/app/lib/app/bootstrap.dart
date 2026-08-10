import 'dart:async';

import 'package:flutter/widgets.dart';

import '../platform/desktop/desktop_window.dart';
import 'startup/startup_service.dart';
import 'web_url_strategy.dart';

Future<void> bootstrap(FutureOr<void> Function() runApp) async {
  // Path URLs (`/login`) — MUST run before WidgetsFlutterBinding, otherwise the
  // engine locks HashUrlStrategy and produces `/login#/login`.
  configureAppUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapDesktopWindow();
  await StartupService.run();
  await runApp();
}

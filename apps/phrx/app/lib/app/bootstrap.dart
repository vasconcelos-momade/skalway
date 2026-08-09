import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../platform/desktop/desktop_window.dart';
import 'startup/startup_service.dart';

Future<void> bootstrap(FutureOr<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs on web (`/login`) instead of hash (`/#/login`). No-op on other platforms.
  usePathUrlStrategy();
  await bootstrapDesktopWindow();
  await StartupService.run();
  await runApp();
}

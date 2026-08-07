import 'dart:async';

import 'package:flutter/widgets.dart';

import '../platform/desktop/desktop_window.dart';
import 'startup/startup_service.dart';

Future<void> bootstrap(FutureOr<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapDesktopWindow();
  await StartupService.run();
  await runApp();
}

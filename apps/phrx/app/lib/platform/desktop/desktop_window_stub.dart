import 'package:flutter/foundation.dart';

/// Stub (web / plataformas sem janela nativa gerível).
bool get supportsDesktopWindowControls => false;

Future<void> bootstrapDesktopWindow() async {}

Future<void> minimizeDesktopWindow() async {}

Future<void> toggleMaximizeDesktopWindow() async {}

Future<bool> isDesktopWindowMaximized() async => false;

Future<void> closeDesktopWindow() async {}

Future<void> startDesktopWindowDragging() async {}

VoidCallback? addDesktopWindowListener({
  VoidCallback? onMaximize,
  VoidCallback? onUnmaximize,
  VoidCallback? onEnterFullScreen,
  VoidCallback? onLeaveFullScreen,
  Future<void> Function()? onClose,
}) =>
    null;

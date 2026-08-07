import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop (Linux / Windows / macOS) — mesmo padrão do scalway-gastro-main.
bool get supportsDesktopWindowControls {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

Future<void> bootstrapDesktopWindow() async {
  if (!supportsDesktopWindowControls) return;

  await windowManager.ensureInitialized();
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  // Interceptar fecho (botão / Alt+F4) para logout quando autenticado.
  await windowManager.setPreventClose(true);

  const options = WindowOptions(center: true, title: 'Skalway PhRx');
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> minimizeDesktopWindow() => windowManager.minimize();

Future<void> toggleMaximizeDesktopWindow() async {
  if (await windowManager.isMaximized()) {
    await windowManager.unmaximize();
  } else {
    await windowManager.maximize();
  }
}

Future<bool> isDesktopWindowMaximized() => windowManager.isMaximized();

Future<void> closeDesktopWindow() async {
  await windowManager.setPreventClose(false);
  await windowManager.close();
}

Future<void> startDesktopWindowDragging() => windowManager.startDragging();

VoidCallback? addDesktopWindowListener({
  VoidCallback? onMaximize,
  VoidCallback? onUnmaximize,
  VoidCallback? onEnterFullScreen,
  VoidCallback? onLeaveFullScreen,
  Future<void> Function()? onClose,
}) {
  if (!supportsDesktopWindowControls) return null;

  final listener = _DesktopWindowBridge(
    onMaximize: onMaximize,
    onUnmaximize: onUnmaximize,
    onEnterFullScreen: onEnterFullScreen,
    onLeaveFullScreen: onLeaveFullScreen,
    onClose: onClose,
  );
  windowManager.addListener(listener);
  return () => windowManager.removeListener(listener);
}

class _DesktopWindowBridge extends WindowListener {
  _DesktopWindowBridge({
    this.onMaximize,
    this.onUnmaximize,
    this.onEnterFullScreen,
    this.onLeaveFullScreen,
    this.onClose,
  });

  final VoidCallback? onMaximize;
  final VoidCallback? onUnmaximize;
  final VoidCallback? onEnterFullScreen;
  final VoidCallback? onLeaveFullScreen;
  final Future<void> Function()? onClose;

  @override
  void onWindowMaximize() => onMaximize?.call();

  @override
  void onWindowUnmaximize() => onUnmaximize?.call();

  @override
  void onWindowEnterFullScreen() => onEnterFullScreen?.call();

  @override
  void onWindowLeaveFullScreen() => onLeaveFullScreen?.call();

  @override
  void onWindowClose() {
    onClose?.call();
  }
}

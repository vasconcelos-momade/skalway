import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../core/config/env.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/breakpoints.dart';
import '../platform/desktop/desktop_close_handler.dart';
import '../platform/desktop/desktop_window.dart';
import 'providers/app_theme_mode_provider.dart';
import 'router/go_app_router.dart';

class PharmaErpApp extends ConsumerStatefulWidget {
  const PharmaErpApp({super.key});

  @override
  ConsumerState<PharmaErpApp> createState() => _PharmaErpAppState();
}

class _PharmaErpAppState extends ConsumerState<PharmaErpApp> {
  VoidCallback? _removeCloseListener;
  bool _handlingClose = false;

  @override
  void initState() {
    super.initState();
    if (!supportsDesktopWindowControls) return;
    _removeCloseListener = addDesktopWindowListener(
      onClose: _onSystemClose,
    );
  }

  @override
  void dispose() {
    _removeCloseListener?.call();
    super.dispose();
  }

  Future<void> _onSystemClose() async {
    if (_handlingClose) return;
    _handlingClose = true;
    try {
      await handleDesktopCloseRequest(ref);
    } finally {
      _handlingClose = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final mode = ref.watch(appThemeModeProvider);
    return MaterialApp.router(
      title: Env.appName,
      theme: AppTheme.lightEnterprise(),
      darkTheme: AppTheme.darkEnterprise(),
      themeMode: mode,
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child ?? const SizedBox.shrink(),
          breakpoints: const [
            Breakpoint(start: 0, end: Breakpoints.responsiveMobileEnd, name: MOBILE),
            Breakpoint(
              start: Breakpoints.mobile,
              end: Breakpoints.responsiveTabletEnd,
              name: TABLET,
            ),
            Breakpoint(
              start: Breakpoints.desktop,
              end: double.infinity,
              name: DESKTOP,
            ),
          ],
        );
      },
    );
  }
}

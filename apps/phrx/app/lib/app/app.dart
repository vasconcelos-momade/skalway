import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/breakpoints.dart';
import 'providers/app_theme_mode_provider.dart';
import 'router/go_app_router.dart';

class PharmaErpApp extends ConsumerWidget {
  const PharmaErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final mode = ref.watch(appThemeModeProvider);
    return MaterialApp.router(
      title: 'Pharma ERP',
      theme: AppTheme.lightEnterprise(),
      darkTheme: AppTheme.darkEnterprise(),
      themeMode: mode,
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
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

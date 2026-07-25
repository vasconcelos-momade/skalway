import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/layouts/dashboard_layout.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../navigation/platform_nav_config.dart';

/// Shell do painel SaaS — reutiliza [DashboardLayout] com menu da plataforma.
class PlatformMainShell extends ConsumerWidget {
  const PlatformMainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformNav = platformNavItemsFlat()
        .map(
          (item) => AppNavItem(
            section: item.section,
            label: item.label,
            path: item.path,
            icon: item.icon,
          ),
        )
        .toList();

    return DashboardLayout(
      navItemsOverride: platformNav,
      appTitle: 'Skalway Admin',
      showSyncStrip: false,
      child: child,
    );
  }
}

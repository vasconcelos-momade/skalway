import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/layouts/dashboard_layout.dart';
import '../navigation/platform_nav_config.dart';
import '../widgets/platform_more_bottom_sheet.dart';

/// Shell do Painel Admin (SaaS) — navegação Enterprise exclusiva da plataforma.
class PlatformMainShell extends ConsumerWidget {
  const PlatformMainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLayout(
      navSectionsOverride: kPlatformNavSections,
      appTitle: 'PhRx Platform',
      brandTitle: 'PhRx Platform',
      brandSubtitle: 'Super Administração',
      searchHint: 'Pesquisar módulo...',
      sectionTitleResolver: platformSectionTitleForPath,
      bottomNav: DashboardBottomNavConfig(
        destinations: [
          for (final item in kPlatformBottomNavPrimary)
            DashboardBottomNavDestination(
              label: item.label,
              path: item.path,
              icon: item.icon,
            ),
          const DashboardBottomNavDestination(
            label: 'Mais',
            path: '__more__',
            icon: Icons.more_horiz_rounded,
            opensMore: true,
          ),
        ],
        pathMatches: platformNavPathMatches,
        onMore: showPlatformMoreBottomSheet,
        fallbackIndex: 4,
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_theme_mode_provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
import '../../platform/desktop/desktop_title_bar.dart';
import '../responsive/pharma_screen_layout.dart';
import '../widgets/menus/enterprise_dropdown_menu.dart';
import '../widgets/sync/offline_mode_banner.dart';

/// Layout autenticação: fundo do design system e indicadores offline.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.showOfflineBanner = false,
    this.offlineMessage,
    this.footer,
    this.scrollPadding,
  });

  final Widget child;
  final bool showOfflineBanner;
  final String? offlineMessage;
  final Widget? footer;
  final EdgeInsets? scrollPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final pagePadding = PharmaScreenLayout.pagePadding(context);
    return Scaffold(
      backgroundColor: t.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
                  child: Padding(
                    padding: pagePadding.copyWith(bottom: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: s.md),
                          child: Row(
                            children: [
                              DesktopWindowDragArea(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: t.minTouchTarget,
                                      height: t.minTouchTarget,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(t.radiusMd),
                                        child: Image.asset(
                                          'assets/logos/logo_512.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: s.md),
                                    Text(
                                      'PhRx',
                                      style: Theme.of(context)
                                          .textTheme
                                          .erpAppName,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              const _ThemeModeMenuButton(),
                              const DesktopWindowControls(),
                            ],
                          ),
                        ),
                        if (showOfflineBanner)
                          OfflineModeBanner(
                            message:
                                offlineMessage ??
                                'A trabalhar em modo offline. As alterações serão sincronizadas.',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: scrollPadding ?? pagePadding,
              child: child,
            ),
          ),
          if (footer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(child: footer!),
            ),
        ],
      ),
    );
  }
}

class _ThemeModeMenuButton extends ConsumerWidget {
  const _ThemeModeMenuButton();

  IconData _icon(ThemeMode themeMode) => switch (themeMode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  String _tooltip(ThemeMode themeMode) => switch (themeMode) {
        ThemeMode.light => 'Tema claro',
        ThemeMode.dark => 'Tema escuro',
        ThemeMode.system => 'Tema do sistema',
      };

  Future<void> _openMenu(BuildContext context, WidgetRef ref, ThemeMode themeMode) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height),
      Offset.zero & overlay.size,
    );

    final selected = await showEnterpriseDropdownMenu<ThemeMode>(
      context: context,
      position: position,
      items: [
        EnterpriseDropdownItem(
          value: ThemeMode.light,
          label: 'Tema claro',
          icon: Icons.light_mode_outlined,
          selected: themeMode == ThemeMode.light,
        ),
        EnterpriseDropdownItem(
          value: ThemeMode.dark,
          label: 'Tema escuro',
          icon: Icons.dark_mode_outlined,
          selected: themeMode == ThemeMode.dark,
        ),
        EnterpriseDropdownItem(
          value: ThemeMode.system,
          label: 'Tema do sistema',
          icon: Icons.brightness_auto_outlined,
          selected: themeMode == ThemeMode.system,
        ),
      ],
    );

    if (selected != null) {
      ref.read(appThemeModeProvider.notifier).setMode(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final themeMode = ref.watch(appThemeModeProvider);

    return IconButton(
      constraints: BoxConstraints(
        minWidth: t.minTouchTarget,
        minHeight: t.minTouchTarget,
      ),
      padding: EdgeInsets.zero,
      tooltip: _tooltip(themeMode),
      onPressed: () => _openMenu(context, ref, themeMode),
      icon: Icon(_icon(themeMode), color: t.textSecondary, size: t.iconMd),
    );
  }
}


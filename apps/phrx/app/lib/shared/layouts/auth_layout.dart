import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
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
                    padding: t.density.pageInsets.copyWith(bottom: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: s.md),
                          child: Row(
                            children: [
                              SizedBox(
                                width: t.minTouchTarget,
                                height: t.minTouchTarget,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(t.radiusMd),
                                  child: Image.asset(
                                    'assets/logos/logo_512.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: s.md),
                              Text(
                                'Pharma ERP',
                                style: Theme.of(context).textTheme.erpAppName,
                              ),
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
              padding: scrollPadding ?? SpacingTokens.pagePadding,
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

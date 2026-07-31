import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'spacing_tokens.dart';

/// Sombras mínimas Trae — só em floating (dialogs, dropdowns, menus).
///
/// A profundidade vem das superfícies, não de sombras fortes.
abstract final class ShadowTokens {
  ShadowTokens._();

  static const List<BoxShadow> none = [];

  /// Sombra mínima para dialogs / dropdowns / menus / popovers.
  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<PharmaTokens>() ??
        (isDark
            ? PharmaTokens.enterpriseDark()
            : PharmaTokens.enterpriseLight());

    return [
      BoxShadow(
        color: tokens.textPrimary.withValues(alpha: isDark ? 0.18 : 0.04),
        blurRadius: SpacingTokens.lg,
        offset: const Offset(0, SpacingTokens.xs),
      ),
    ];
  }

  /// Alias semântico.
  static List<BoxShadow> dialog(BuildContext context) => floating(context);

  /// Elevação mínima na aresta vertical (sidebar / side sheet).
  static List<BoxShadow> panelEdge(
    BuildContext context, {
    required bool fromLeft,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<PharmaTokens>() ??
        (isDark
            ? PharmaTokens.enterpriseDark()
            : PharmaTokens.enterpriseLight());
    final dx = fromLeft ? SpacingTokens.xs : -SpacingTokens.xs;

    return [
      BoxShadow(
        color: tokens.textPrimary.withValues(alpha: isDark ? 0.22 : 0.06),
        blurRadius: SpacingTokens.sm,
        offset: Offset(dx, 0),
      ),
    ];
  }
}

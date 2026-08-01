import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'spacing_tokens.dart';

/// Sombras mínimas enterprise — floating (dialogs/menus) e cards leves.
///
/// A profundidade vem das superfícies; sombras são discretas.
abstract final class ShadowTokens {
  ShadowTokens._();

  static const List<BoxShadow> none = [];

  /// Sombra muito leve para cards / superfícies elevadas discretas.
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<PharmaTokens>() ??
        (isDark
            ? PharmaTokens.enterpriseDark()
            : PharmaTokens.enterpriseLight());

    return [
      BoxShadow(
        color: tokens.textPrimary.withValues(alpha: isDark ? 0.12 : 0.03),
        blurRadius: SpacingTokens.sm,
        offset: const Offset(0, 1),
      ),
    ];
  }

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

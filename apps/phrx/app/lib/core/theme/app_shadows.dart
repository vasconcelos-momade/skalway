import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Sombras semânticas (adaptam-se ao brightness / tokens).
abstract final class AppShadows {
  AppShadows._();

  static List<BoxShadow> dialog(BuildContext context) {
    final tokens = Theme.of(context).extension<PharmaTokens>() ??
        PharmaTokens.enterpriseDark();
    final s = tokens.density;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark ? Colors.black : tokens.textPrimary;

    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: isDark ? 0.45 : 0.1),
        blurRadius: s.xxl,
        spreadRadius: 0,
        offset: Offset(0, s.sm),
      ),
      BoxShadow(
        color: shadowColor.withValues(alpha: isDark ? 0.25 : 0.04),
        blurRadius: s.xl,
        spreadRadius: 0,
        offset: Offset(0, s.xs),
      ),
    ];
  }
}

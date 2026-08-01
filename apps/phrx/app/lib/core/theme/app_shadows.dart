import 'package:flutter/material.dart';

import 'shadow_tokens.dart';

/// Sombras enterprise — card leve + floating (dialog / dropdown).
abstract final class AppShadows {
  AppShadows._();

  /// Sombra muito leve para cards.
  static List<BoxShadow> card(BuildContext context) =>
      ShadowTokens.card(context);

  static List<BoxShadow> dialog(BuildContext context) =>
      ShadowTokens.dialog(context);

  /// Alias para dropdowns / popovers (mesmo peso que dialog).
  static List<BoxShadow> floating(BuildContext context) =>
      ShadowTokens.floating(context);

  /// Elevação mínima na aresta vertical (sidebar → direita, side sheet → esquerda).
  static List<BoxShadow> panelEdge(
    BuildContext context, {
    required bool fromLeft,
  }) =>
      ShadowTokens.panelEdge(context, fromLeft: fromLeft);
}

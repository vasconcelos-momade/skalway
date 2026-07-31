import 'package:flutter/material.dart';

import 'shadow_tokens.dart';

/// Sombras Trae — praticamente ausentes; só floating (dialog / dropdown).
abstract final class AppShadows {
  AppShadows._();

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

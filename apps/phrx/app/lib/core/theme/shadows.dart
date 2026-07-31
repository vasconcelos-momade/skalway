import 'package:flutter/widgets.dart';

import 'shadow_tokens.dart';

export 'shadow_tokens.dart';

/// Escala de sombra legada — vazia (profundidade via superfícies).
abstract final class ShadowScale {
  ShadowScale._();

  static const List<BoxShadow> xs = ShadowTokens.none;
  static const List<BoxShadow> sm = ShadowTokens.none;
  static const List<BoxShadow> md = ShadowTokens.none;
  static const List<BoxShadow> lg = ShadowTokens.none;
  static const List<BoxShadow> xl = ShadowTokens.none;
}

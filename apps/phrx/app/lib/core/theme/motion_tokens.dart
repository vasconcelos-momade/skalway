import 'package:flutter/animation.dart';

/// Tokens de motion enterprise.
///
/// | Token | Duração |
/// |-------|---------|
/// | Fast | 150ms |
/// | Normal | 200ms |
/// | Slow | 250ms |
abstract final class MotionTokens {
  MotionTokens._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);

  /// Curva padrão (saída suave).
  static const Curve ease = Curves.easeOut;

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve emphasized = Curves.fastOutSlowIn;

  // Aliases legados
  static const Duration durationFast = fast;
  static const Duration durationNormal = normal;
  static const Duration durationSlow = slow;
}

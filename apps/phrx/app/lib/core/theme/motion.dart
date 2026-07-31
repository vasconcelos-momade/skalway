import 'package:flutter/animation.dart';

import 'motion_tokens.dart';

export 'motion_tokens.dart';

/// Aliases legados de motion — preferir [MotionTokens].
abstract final class Motion {
  Motion._();

  static const Duration durationFastest = MotionTokens.fast;
  static const Duration durationFaster = MotionTokens.fast;
  static const Duration durationFast = MotionTokens.normal;
  static const Duration durationNormal = MotionTokens.slow;
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationSlower = Duration(milliseconds: 400);

  static const Curve ease = Curves.ease;
  static const Curve easeIn = MotionTokens.easeIn;
  static const Curve easeOut = MotionTokens.ease;
  static const Curve easeInOut = MotionTokens.easeInOut;
  static const Curve emphasized = MotionTokens.emphasized;
}

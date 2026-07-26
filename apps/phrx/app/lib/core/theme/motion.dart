import 'package:flutter/widgets.dart';

abstract final class Motion {
  Motion._();

  // Durations
  static const Duration durationFastest = Duration(milliseconds: 100);
  static const Duration durationFaster = Duration(milliseconds: 150);
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationSlower = Duration(milliseconds: 400);

  // Curves
  static const Curve ease = Curves.ease;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve emphasized = Curves.fastOutSlowIn;
}

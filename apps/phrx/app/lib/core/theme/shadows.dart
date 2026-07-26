import 'package:flutter/widgets.dart';

abstract final class ShadowScale {
  ShadowScale._();

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 3, spreadRadius: 1),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 10), blurRadius: 15, spreadRadius: -3),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -4),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 8), blurRadius: 10, spreadRadius: -6),
  ];
}

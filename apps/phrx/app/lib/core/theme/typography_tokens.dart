import 'package:flutter/material.dart';

/// Tokens tipográficos canónicos do Design System.
///
/// Pesos permitidos: **400, 500, 600**.
abstract final class TypographyTokens {
  TypographyTokens._();

  // ── Weights ──────────────────────────────────────────────────────────
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;

  // ── Scale (px) ───────────────────────────────────────────────────────
  static const double display = 28;
  static const double heading = 20;
  static const double title = 16;
  static const double subtitle = 14;
  static const double body = 14;
  static const double bodySmall = 13;
  static const double label = 14;
  static const double caption = 12;
  /// Label acima do campo (não floating) — 12–13px, peso 500.
  static const double fieldLabel = 12.5;
  static const double tableHeader = 13;
  static const double tableCell = 13;
  static const double appBar = 18;

  // ── Line heights ─────────────────────────────────────────────────────
  static const double displayHeight = 1.15;
  static const double headingHeight = 1.25;
  static const double titleHeight = 1.25;
  static const double bodyHeight = 1.4;
  static const double captionHeight = 1.4;
  static const double tableHeight = 1.25;
}

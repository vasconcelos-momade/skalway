import 'package:flutter/material.dart';

/// Paleta semântica **Pharma ERP** — azul farmacêutico, verde hospitalar, neutros e alertas.
/// Preferir `context.pharmaTokens` para valores que variam com light/dark; use estes para seeds e gráficos.
abstract final class AppColors {
  AppColors._();

  /// Azul farmacêutico (identidade, informação, links).
  static const Color pharmaBlue = Color(0xFF0284C7);
  static const Color pharmaBlueDeep = Color(0xFF0369A1);
  static const Color pharmaBlueSoft = Color(0xFF38BDF8);

  /// Verde hospitalar / operação.
  static const Color hospitalGreen = Color(0xFF059669);
  static const Color hospitalGreenBright = Color(0xFF22C55E);

  /// Neutros escuros (surfaces enterprise dark).
  static const Color ink950 = Color(0xFF05060A);
  static const Color ink900 = Color(0xFF0B0F14);
  static const Color ink800 = Color(0xFF11161D);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate400 = Color(0xFF94A3B8);

  /// Neutros claros (surfaces enterprise light).
  static const Color cloud50 = Color(0xFFF8FAFC);
  static const Color cloud100 = Color(0xFFF1F5F9);
  static const Color cloud200 = Color(0xFFE2E8F0);

  /// Alertas operacionais.
  static const Color critical = Color(0xFFDC2626);
  static const Color attention = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF2563EB);

  /// Cor primária Material legada (compat).
  static const Color primary = hospitalGreenBright;
  static const Color onPrimary = ink950;
}

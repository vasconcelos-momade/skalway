import 'package:flutter/material.dart';

/// Paleta semântica **Pharma ERP** — filosofia visual Trae AI.
///
/// Superfícies dark/light partilham a mesma API; widgets devem preferir
/// `context.pharmaTokens` / `context.colors` / `context.surfaces`.
abstract final class AppColors {
  AppColors._();

  // ── Brand (identidade — não alterar) ──────────────────────────────────
  static const Color pharmaBlue = Color(0xFF0284C7);
  static const Color pharmaBlueDeep = Color(0xFF0369A1);
  static const Color pharmaBlueSoft = Color(0xFF38BDF8);

  static const Color hospitalGreen = Color(0xFF059669);
  static const Color hospitalGreenBright = Color(0xFF22C55E);

  static const Color critical = Color(0xFFDC2626);
  static const Color attention = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF2563EB);

  static const Color primary = hospitalGreenBright;
  static const Color onPrimary = Color(0xFF09090B);
  static const Color error = critical;
  static const Color warning = attention;

  // ── Legacy aliases (compat) ───────────────────────────────────────────
  static const Color ink950 = AppColorsDark.surface0;
  static const Color ink900 = AppColorsDark.surface1;
  static const Color ink800 = AppColorsDark.surface2;
  static const Color ink700 = AppColorsDark.surface3;
  static const Color ink600 = AppColorsDark.surface4;
  static const Color slate600 = Color(0xFF475569);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color cloud50 = AppColorsLight.surface0;
  static const Color cloud100 = AppColorsLight.surface3;
  static const Color cloud200 = Color(0xFFE4E4E7);
  static const Color borderDark = AppColorsDark.border;
  static const Color borderLight = AppColorsLight.border;

  static const Color surface0 = AppColorsDark.surface0;
  static const Color surface1 = AppColorsDark.surface1;
  static const Color surface2 = AppColorsDark.surface2;
  static const Color surface3 = AppColorsDark.surface3;
  static const Color surface4 = AppColorsDark.surface4;
  static const Color border = AppColorsDark.border;
  static const Color textPrimary = AppColorsDark.textPrimary;
  static const Color textSecondary = AppColorsDark.textSecondary;
  static const Color textDisabled = AppColorsDark.textDisabled;
}

/// Dark Mode — Trae: body / sidebar / side sheet partilham o mesmo fundo;
/// cards e overlays sobem ligeiramente em luminosidade.
abstract final class AppColorsDark {
  AppColorsDark._();

  /// Surface 0 — body.
  static const Color surface0 = Color(0xFF0A0A0B);

  /// Surface 1 — sidebar / side sheet (ligeira elevação face ao body).
  static const Color surface1 = Color(0xFF101012);

  /// Surface 2 — cards / tables.
  static const Color surface2 = Color(0xFF141416);

  /// Surface 3 — toolbars / headers.
  static const Color surface3 = Color(0xFF1A1A1D);

  /// Surface 4 — dialogs / menus / popovers.
  static const Color surface4 = Color(0xFF222226);

  /// Borda ≈ white 10%.
  static const Color border = Color(0x1AFFFFFF);

  /// Borda subtle ≈ white 8%.
  static const Color borderSubtle = Color(0x14FFFFFF);

  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textDisabled = Color(0xFF71717A);
}

/// Light Mode — Trae: body / sidebar / side sheet partilham o mesmo fundo;
/// contraste via bordas, não via blocos cinzentos.
abstract final class AppColorsLight {
  AppColorsLight._();

  /// Surface 0 — body.
  static const Color surface0 = Color(0xFFFFFFFF);

  /// Surface 1 — sidebar / side sheet (ligeira elevação face ao body).
  static const Color surface1 = Color(0xFFFAFAFA);

  /// Surface 2 — cards / tables (mesmo branco; contraste via borda).
  static const Color surface2 = Color(0xFFFFFFFF);

  /// Surface 3 — toolbars / headers.
  static const Color surface3 = Color(0xFFFAFAFA);

  /// Surface 4 — dialogs / menus / popovers.
  static const Color surface4 = Color(0xFFFFFFFF);

  /// Borda ≈ slate 10%.
  static const Color border = Color(0x1A18181B);

  /// Borda subtle ≈ slate 8%.
  static const Color borderSubtle = Color(0x1418181B);

  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textDisabled = Color(0xFFA1A1AA);
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

/// Hierarquia de superfícies Trae.
///
/// **Body = Sidebar = Side sheet** (mesmo fundo; separação por borda).
/// Cards / dialogs elevam-se ligeiramente (dark) ou só por borda (light).
///
/// | Nível | Uso |
/// |-------|-----|
/// | 0 | Body |
/// | 1 | Sidebar / side sheet (= 0) |
/// | 2 | Cards / tables |
/// | 3 | Toolbars / headers |
/// | 4 | Dialogs / menus / popovers |
@immutable
class SurfaceTokens {
  const SurfaceTokens({
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.surface4,
  });

  /// Background principal (body).
  final Color surface0;

  /// Sidebar / app chrome.
  final Color surface1;

  /// Cards, containers, data tables.
  final Color surface2;

  /// Toolbars / headers.
  final Color surface3;

  /// Dialogs, dropdowns, menus, popovers.
  /// (Side sheet = [surface1], alinhado à sidebar.)
  final Color surface4;

  static const SurfaceTokens dark = SurfaceTokens(
    surface0: AppColorsDark.surface0,
    surface1: AppColorsDark.surface1,
    surface2: AppColorsDark.surface2,
    surface3: AppColorsDark.surface3,
    surface4: AppColorsDark.surface4,
  );

  static const SurfaceTokens light = SurfaceTokens(
    surface0: AppColorsLight.surface0,
    surface1: AppColorsLight.surface1,
    surface2: AppColorsLight.surface2,
    surface3: AppColorsLight.surface3,
    surface4: AppColorsLight.surface4,
  );

  factory SurfaceTokens.fromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  factory SurfaceTokens.fromPharma(PharmaTokens tokens) => SurfaceTokens(
        surface0: tokens.surface0,
        surface1: tokens.surface1,
        surface2: tokens.surface2,
        surface3: tokens.surface3,
        surface4: tokens.surface4,
      );
}

extension SurfaceTokensX on BuildContext {
  SurfaceTokens get surfaces => SurfaceTokens.fromPharma(pharmaTokens);
}

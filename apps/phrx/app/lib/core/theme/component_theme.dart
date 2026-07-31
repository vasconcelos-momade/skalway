import 'package:flutter/material.dart';

import 'design_metrics.dart';
import 'design_tokens.dart';
import 'pharma_color_tokens.dart';
import 'typography.dart';

abstract final class PharmaComponentTheme {
  PharmaComponentTheme._();

  static ButtonStyle _baseButtonStyle(
    PharmaTokens tokens, {
    required TextStyle textStyle,
    bool compact = false,
  }) {
    // Altura fixa = search/select ([PharmaTokens.controlHeight]).
    // Só padding horizontal — a altura vem do token, não do padding vertical.
    final height = compact ? tokens.compactControlHeight : tokens.controlHeight;
    final horizontal = tokens.density.buttonPadding.left;
    return ButtonStyle(
      animationDuration: MotionTokens.durationFast,
      minimumSize: WidgetStateProperty.all(
        Size(tokens.minTouchTarget, height),
      ),
      maximumSize: WidgetStateProperty.all(
        Size(double.infinity, height),
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: horizontal),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
      textStyle: WidgetStateProperty.all(textStyle),
    );
  }

  static ButtonStyle filled(
    PharmaTokens tokens,
    ColorScheme scheme, {
    PharmaColorTokens? colors,
    TextTheme? textTheme,
    bool compact = false,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    final palette = colors;
    return _baseButtonStyle(tokens, textStyle: theme.erpButtonPrimary, compact: compact).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette?.disabled ?? scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return tokens.brandGreenHover;
        }
        if (states.contains(WidgetState.hovered)) {
          return Color.alphaBlend(
            scheme.onPrimary.withValues(alpha: 0.08),
            scheme.primary,
          );
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.white.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.06);
        }
        if (states.contains(WidgetState.focused)) {
          return Colors.white.withValues(alpha: 0.08);
        }
        return null;
      }),
    );
  }

  static ButtonStyle outlined(
    PharmaTokens tokens,
    ColorScheme scheme, {
    PharmaColorTokens? colors,
    TextTheme? textTheme,
    bool compact = false,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    final palette = colors;
    return _baseButtonStyle(
      tokens,
      textStyle: theme.erpButtonSecondary,
      compact: compact,
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return palette?.primarySubtle ?? scheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return palette?.neutralSubtle ?? scheme.primary.withValues(alpha: 0.06);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return tokens.textPrimary;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: tokens.borderSubtle);
        }
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered)) {
          return BorderSide(color: scheme.primary);
        }
        return BorderSide(color: tokens.border);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.10);
        }
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.06);
        }
        return null;
      }),
    );
  }

  static ButtonStyle text(
    PharmaTokens tokens,
    ColorScheme scheme, {
    PharmaColorTokens? colors,
    TextTheme? textTheme,
    bool compact = false,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    final palette = colors;
    return _baseButtonStyle(
      tokens,
      textStyle: theme.erpButtonSecondary,
      compact: compact,
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return tokens.textSecondary;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return scheme.onSurface.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return scheme.onSurface.withValues(alpha: 0.04);
        }
        return null;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return palette?.neutralSubtle ?? scheme.onSurface.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return palette?.neutralSubtle ?? scheme.onSurface.withValues(alpha: 0.04);
        }
        return Colors.transparent;
      }),
    );
  }

  static IconButtonThemeData iconButton(
    PharmaTokens tokens,
    ColorScheme scheme, {
    PharmaColorTokens? colors,
    bool compact = false,
  }) {
    final size = compact ? tokens.compactControlHeight : tokens.controlHeight;
    final palette = colors;
    return IconButtonThemeData(
      style: ButtonStyle(
        animationDuration: MotionTokens.durationFast,
        minimumSize: WidgetStateProperty.all(Size.square(size)),
        maximumSize: WidgetStateProperty.all(Size.square(size)),
        fixedSize: WidgetStateProperty.all(Size.square(size)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          return scheme.onSurface;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return palette?.neutralSubtle ?? scheme.onSurface.withValues(alpha: 0.10);
          }
          if (states.contains(WidgetState.hovered)) {
            return palette?.neutralSubtle ?? scheme.onSurface.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.focused)) {
            return palette?.primarySubtle ?? scheme.primary.withValues(alpha: 0.10);
          }
          return null;
        }),
      ),
    );
  }

  static InputDecorationTheme input(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    PharmaColorTokens? colors,
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    final palette = colors;
    final baseBorderColor = tokens.border;
    final disabledBorderColor = tokens.borderSubtle.withValues(alpha: 0.55);
    final focusedBorderColor = scheme.primary;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      borderSide: BorderSide(
        color: baseBorderColor,
        width: BorderTokens.width,
      ),
    );

    return InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      hoverColor: palette?.fieldHover ?? Colors.transparent,
      isDense: false,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.density.inputPadding.left,
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: tokens.controlHeight,
        minHeight: tokens.controlHeight,
        maxHeight: tokens.controlHeight,
      ),
      suffixIconConstraints: BoxConstraints(
        minWidth: tokens.controlHeight,
        minHeight: tokens.controlHeight,
        maxHeight: tokens.controlHeight,
      ),
      border: border,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: baseBorderColor,
          width: BorderTokens.width,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: disabledBorderColor,
          width: BorderTokens.width,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: focusedBorderColor,
          width: BorderTokens.width,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.posDanger, width: BorderTokens.width),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.posDanger, width: BorderTokens.width),
      ),
      labelStyle: theme.erpSelectLabel.copyWith(
        color: tokens.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: theme.erpFieldLabel.copyWith(color: tokens.textSecondary),
      hintStyle: theme.erpBody.copyWith(color: tokens.textDisabled),
    );
  }

  static ChipThemeData chip(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    PharmaColorTokens? colors,
    TextTheme? textTheme,
  }) {
    final label = (textTheme ?? ThemeData().textTheme).erpLabel.copyWith(
      color: tokens.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return ChipThemeData(
      backgroundColor: colors?.neutralSubtle ?? tokens.card,
      selectedColor: colors?.primarySubtle ?? scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
      disabledColor: scheme.onSurface.withValues(alpha: 0.08),
      labelStyle: label,
      secondaryLabelStyle: label,
      side: BorderSide(color: tokens.borderSubtle),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.density.sm,
        vertical: tokens.density.xs,
      ),
    );
  }

  static TooltipThemeData tooltip(
    PharmaTokens tokens,
    ColorScheme scheme, {
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.overlay,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: tokens.border),
      ),
      textStyle: theme.erpCaption.copyWith(color: tokens.textPrimary),
      preferBelow: true,
      waitDuration: MotionTokens.fast,
    );
  }

  static SnackBarThemeData snackBar(
    PharmaTokens tokens,
    ColorScheme scheme, {
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return SnackBarThemeData(
      backgroundColor: tokens.overlay,
      contentTextStyle: theme.erpBody.copyWith(color: tokens.textPrimary),
      actionTextColor: scheme.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(color: tokens.border),
      ),
    );
  }

  static ScrollbarThemeData scrollbar(PharmaTokens tokens) {
    return ScrollbarThemeData(
      radius: Radius.circular(tokens.radiusMd),
      thickness: WidgetStateProperty.all(6),
      thumbVisibility: WidgetStateProperty.all(false),
    );
  }

  static CardThemeData card(PharmaTokens tokens, {required bool isDark}) {
    return CardThemeData(
      color: tokens.surface2,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(color: tokens.borderSubtle),
      ),
    );
  }

  static DialogThemeData dialog(PharmaTokens tokens, {required bool isDark}) {
    return DialogThemeData(
      backgroundColor: tokens.surface4,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusXl),
        side: BorderSide(color: tokens.borderSubtle),
      ),
    );
  }

  static BottomSheetThemeData bottomSheet(PharmaTokens tokens) {
    return BottomSheetThemeData(
      backgroundColor: tokens.surface4,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusXl),
        ),
        side: BorderSide(color: tokens.borderSubtle),
      ),
    );
  }

  static PopupMenuThemeData popupMenu(
    PharmaTokens tokens, {
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return PopupMenuThemeData(
      color: tokens.surface4,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusXl),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      textStyle: theme.erpMenuItem.copyWith(color: tokens.textPrimary),
    );
  }

  static MenuThemeData menu(PharmaTokens tokens, {TextTheme? textTheme}) {
    return MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(tokens.surface4),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusXl),
            side: BorderSide(color: tokens.borderSubtle),
          ),
        ),
      ),
    );
  }

  static CheckboxThemeData checkbox(ColorScheme scheme) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(scheme.onPrimary),
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.06);
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.10);
        }
        return null;
      }),
    );
  }

  static SwitchThemeData switchTheme(ColorScheme scheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return states.contains(WidgetState.selected)
            ? scheme.primary.withValues(alpha: 0.6)
            : scheme.onSurface.withValues(alpha: 0.25);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.06);
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.10);
        }
        return null;
      }),
    );
  }

  static RadioThemeData radio(ColorScheme scheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurface;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.06);
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.10);
        }
        return null;
      }),
    );
  }

  static SliderThemeData slider(ColorScheme scheme, {TextTheme? textTheme}) {
    final theme = textTheme ?? ThemeData().textTheme;
    return SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.18),
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.10),
      valueIndicatorColor: scheme.inverseSurface,
      valueIndicatorTextStyle: theme.erpCaption.copyWith(
        color: scheme.onInverseSurface,
      ),
    );
  }

  static DividerThemeData divider(PharmaTokens tokens, {required bool isDark}) {
    return DividerThemeData(
      color: tokens.border,
      thickness: 1,
      space: 1,
    );
  }

  static DataTableThemeData dataTable(
    PharmaTokens tokens, {
    PharmaColorTokens? colors,
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(
        colors?.surfaceContainerLow ?? tokens.surface1,
      ),
      headingTextStyle: theme.erpTableHeader.copyWith(
        color: tokens.textSecondary,
      ),
      dataTextStyle: theme.erpTableSecondary.copyWith(
        color: tokens.textPrimary,
      ),
      dividerThickness: BorderTokens.width,
      horizontalMargin: tokens.density.md,
      columnSpacing: tokens.density.lg,
      dataRowMinHeight: DesignMetrics.tableRowHeightMin,
      dataRowMaxHeight: DesignMetrics.tableRowHeightMax,
    );
  }

  static ListTileThemeData listTile(PharmaTokens tokens) {
    return ListTileThemeData(
      iconColor: tokens.textSecondary,
      textColor: tokens.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      selectedTileColor: tokens.surface3,
    );
  }

  static NavigationRailThemeData navigationRail(
    PharmaTokens tokens,
    ColorScheme scheme, {
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return NavigationRailThemeData(
      backgroundColor: tokens.bgSecondary,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: tokens.textSecondary),
      selectedLabelTextStyle: theme.erpMenuItemActive.copyWith(
        color: scheme.primary,
      ),
      unselectedLabelTextStyle: theme.erpMenuItem.copyWith(
        color: tokens.textSecondary,
      ),
    );
  }

  static NavigationDrawerThemeData navigationDrawer(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    PharmaColorTokens? colors,
  }) {
    return NavigationDrawerThemeData(
      backgroundColor: tokens.bgSecondary,
      indicatorColor:
          colors?.sidebarActiveBackground ??
          scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
    );
  }

  static NavigationBarThemeData navigationBar(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    PharmaColorTokens? colors,
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return NavigationBarThemeData(
      backgroundColor: tokens.bgSecondary,
      indicatorColor:
          colors?.sidebarActiveBackground ??
          scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return selected
            ? theme.erpMenuItemActive.copyWith(color: tokens.textPrimary)
            : theme.erpMenuItem.copyWith(color: tokens.textSecondary);
      }),
      height: DesignMetrics.tabHeightMax,
    );
  }

  static ProgressIndicatorThemeData progressIndicator(ColorScheme scheme) {
    return ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.onSurface.withValues(alpha: 0.08),
      circularTrackColor: scheme.onSurface.withValues(alpha: 0.08),
    );
  }

  static TabBarThemeData tabBar(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    required TextTheme textTheme,
  }) {
    return TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: tokens.textSecondary,
      labelStyle: textTheme.erpTabLabel,
      unselectedLabelStyle: textTheme.erpTabLabel.copyWith(
        fontWeight: FontWeight.w500,
        color: tokens.textSecondary,
      ),
      indicatorColor: scheme.primary,
      dividerColor: tokens.border,
      labelPadding: EdgeInsets.symmetric(horizontal: tokens.density.md),
    );
  }
}

import 'package:flutter/material.dart';

import 'design_metrics.dart';
import 'design_tokens.dart';
import 'pharma_surface.dart';
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
      animationDuration: kPharmaInstantThemeDuration,
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
    TextTheme? textTheme,
    bool compact = false,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return _baseButtonStyle(tokens, textStyle: theme.erpButtonPrimary, compact: compact).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
    );
  }

  static ButtonStyle outlined(
    PharmaTokens tokens,
    ColorScheme scheme, {
    TextTheme? textTheme,
    bool compact = false,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return _baseButtonStyle(
      tokens,
      textStyle: theme.erpButtonSecondary,
      compact: compact,
    ).copyWith(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.primary;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: scheme.onSurface.withValues(alpha: 0.12));
        }
        return BorderSide(color: scheme.outline);
      }),
    );
  }

  static ButtonStyle text(
    PharmaTokens tokens,
    ColorScheme scheme, {
    TextTheme? textTheme,
    bool compact = false,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return _baseButtonStyle(
      tokens,
      textStyle: theme.erpButtonSecondary,
      compact: compact,
    ).copyWith(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.primary;
      }),
    );
  }

  static IconButtonThemeData iconButton(
    PharmaTokens tokens,
    ColorScheme scheme, {
    bool compact = false,
  }) {
    final size = compact ? tokens.compactControlHeight : tokens.controlHeight;
    return IconButtonThemeData(
      style: ButtonStyle(
        animationDuration: kPharmaInstantThemeDuration,
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
      ),
    );
  }

  static InputDecorationTheme input(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      borderSide: BorderSide(color: tokens.border, width: 1),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? tokens.card.withValues(alpha: 0.35) : Colors.white,
      // isDense:false → minContainerHeight = kMinInteractiveDimension (48)
      // = [PharmaTokens.controlHeight]. isDense:true usa só a altura do texto
      // e deixa os campos mais baixos que os botões.
      // Não usar decoration.constraints: o ConstrainedBox envolve label+helper
      // e esmaga o campo (não é a altura da caixa do input).
      isDense: false,
      // auto: label dentro quando vazio; flutua para a borda ao focar/preencher.
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      // Só padding horizontal — a altura vem do piso MD3 (igual aos botões).
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
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.posDanger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.posDanger, width: 2),
      ),
      labelStyle: theme.erpSelectLabel.copyWith(color: tokens.textSecondary),
      hintStyle: theme.erpBody.copyWith(color: tokens.textMuted),
    );
  }

  static ChipThemeData chip(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    TextTheme? textTheme,
  }) {
    final label = (textTheme ?? ThemeData().textTheme).erpLabel.copyWith(
      color: tokens.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return ChipThemeData(
      backgroundColor: tokens.card,
      selectedColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      disabledColor: scheme.onSurface.withValues(alpha: 0.08),
      labelStyle: label,
      secondaryLabelStyle: label,
      side: BorderSide(
        color: tokens.border.withValues(alpha: isDark ? 0.55 : 0.75),
      ),
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
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      textStyle: theme.erpCaption.copyWith(color: scheme.onInverseSurface),
      preferBelow: true,
    );
  }

  static SnackBarThemeData snackBar(
    PharmaTokens tokens,
    ColorScheme scheme, {
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: theme.erpBody.copyWith(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
    );
  }

  static ScrollbarThemeData scrollbar(PharmaTokens tokens) {
    return ScrollbarThemeData(
      radius: Radius.circular(tokens.radiusMd),
      thickness: WidgetStateProperty.all(8),
      thumbVisibility: WidgetStateProperty.all(false),
    );
  }

  static CardThemeData card(PharmaTokens tokens, {required bool isDark}) {
    return CardThemeData(
      color: tokens.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(
          color: tokens.border.withValues(alpha: isDark ? 0.6 : 0.85),
        ),
      ),
    );
  }

  static DialogThemeData dialog(PharmaTokens tokens, {required bool isDark}) {
    return DialogThemeData(
      backgroundColor: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(
          color: tokens.border.withValues(alpha: isDark ? 0.6 : 0.85),
        ),
      ),
    );
  }

  static BottomSheetThemeData bottomSheet(PharmaTokens tokens) {
    return BottomSheetThemeData(
      backgroundColor: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusMd),
        ),
      ),
    );
  }

  static PopupMenuThemeData popupMenu(
    PharmaTokens tokens, {
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return PopupMenuThemeData(
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      textStyle: theme.erpMenuItem.copyWith(color: tokens.textPrimary),
    );
  }

  static MenuThemeData menu(PharmaTokens tokens, {TextTheme? textTheme}) {
    return MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(tokens.card),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
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
        borderRadius: BorderRadius.circular(RadiusScale.xs),
      ),
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
    );
  }

  static SliderThemeData slider(ColorScheme scheme, {TextTheme? textTheme}) {
    final theme = textTheme ?? ThemeData().textTheme;
    return SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.18),
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: scheme.inverseSurface,
      valueIndicatorTextStyle: theme.erpCaption.copyWith(
        color: scheme.onInverseSurface,
      ),
    );
  }

  static DividerThemeData divider(PharmaTokens tokens, {required bool isDark}) {
    return DividerThemeData(
      color: tokens.border.withValues(alpha: isDark ? 0.5 : 0.7),
    );
  }

  static DataTableThemeData dataTable(
    PharmaTokens tokens, {
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(tokens.bgSecondary),
      headingTextStyle: theme.erpTableHeader.copyWith(
        color: tokens.textPrimary,
      ),
      dataTextStyle: theme.erpTableSecondary.copyWith(
        color: tokens.textPrimary,
      ),
      dividerThickness: 1,
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
  }) {
    return NavigationDrawerThemeData(
      backgroundColor: tokens.bgSecondary,
      indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
    );
  }

  static NavigationBarThemeData navigationBar(
    PharmaTokens tokens,
    ColorScheme scheme, {
    required bool isDark,
    TextTheme? textTheme,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    return NavigationBarThemeData(
      backgroundColor: tokens.bgSecondary,
      indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return selected
            ? theme.erpMenuItemActive.copyWith(color: scheme.primary)
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
      dividerColor: tokens.border.withValues(alpha: isDark ? 0.5 : 0.7),
      labelPadding: EdgeInsets.symmetric(horizontal: tokens.density.md),
    );
  }
}

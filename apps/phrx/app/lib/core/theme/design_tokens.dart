import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_metrics.dart';

enum DensityLevel {
  mobile,
  compact,
  comfortable,
}

@immutable
class DensityTokens {
  const DensityTokens({
    required this.level,
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.gutter,
    required this.page,
    required this.cardPadding,
    required this.buttonPadding,
    required this.inputPadding,
  });

  final DensityLevel level;
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double gutter;
  final double page;
  final EdgeInsets cardPadding;
  final EdgeInsets buttonPadding;
  final EdgeInsets inputPadding;

  /// Margens do conteúdo principal (shell das páginas de módulo).
  EdgeInsets get pageInsets => EdgeInsets.fromLTRB(gutter, md, gutter, xxl);

  static const DensityTokens mobile = DensityTokens(
    level: DensityLevel.mobile,
    xxs: SpacingTokens.xs,
    xs: SpacingTokens.xs,
    sm: SpacingTokens.sm,
    md: SpacingTokens.sm,
    lg: SpacingTokens.md,
    xl: SpacingTokens.lg,
    xxl: SpacingTokens.xl,
    xxxl: SpacingTokens.xxl,
    gutter: SpacingTokens.md,
    page: SpacingTokens.md,
    cardPadding: EdgeInsets.all(SpacingTokens.md),
    buttonPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.md,
      vertical: SpacingTokens.sm,
    ),
    inputPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.md,
      vertical: SpacingTokens.sm,
    ),
  );

  static const DensityTokens compact = DensityTokens(
    level: DensityLevel.compact,
    xxs: SpacingTokens.xs,
    xs: SpacingTokens.xs,
    sm: SpacingTokens.sm,
    md: SpacingTokens.md,
    lg: SpacingTokens.lg,
    xl: SpacingTokens.xl,
    xxl: SpacingTokens.xxl,
    xxxl: SpacingTokens.xxxl,
    gutter: SpacingTokens.lg,
    page: SpacingTokens.lg,
    cardPadding: EdgeInsets.all(SpacingTokens.lg),
    buttonPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.lg,
      vertical: SpacingTokens.md,
    ),
    inputPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.lg,
      vertical: SpacingTokens.md,
    ),
  );

  static const DensityTokens comfortable = DensityTokens(
    level: DensityLevel.comfortable,
    xxs: SpacingTokens.xs,
    xs: SpacingTokens.xs,
    sm: SpacingTokens.sm,
    md: SpacingTokens.md,
    lg: SpacingTokens.lg,
    xl: SpacingTokens.xl,
    xxl: SpacingTokens.xxl,
    xxxl: SpacingTokens.xxxl,
    gutter: SpacingTokens.lg,
    page: SpacingTokens.lg,
    cardPadding: EdgeInsets.all(SpacingTokens.lg),
    buttonPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.lg,
      vertical: SpacingTokens.md,
    ),
    inputPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.lg,
      vertical: SpacingTokens.md,
    ),
  );
}

@immutable
class PharmaTokens extends ThemeExtension<PharmaTokens> {
  const PharmaTokens({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.inputBg,
    required this.card,
    required this.cardHover,
    required this.overlay,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.brandBlue,
    required this.brandBlueHover,
    required this.brandGreen,
    required this.brandGreenHover,
    required this.posSuccess,
    required this.posWarning,
    required this.posDanger,
    required this.posInfo,
    required this.psychotropic,
    required this.quarantine,
    required this.incineration,
    required this.recall,
    required this.radiusMd,
    required this.radiusXl,
    required this.radius2xl,
    required this.radius3xl,
    required this.minTouchTarget,
    required this.controlHeight,
    required this.compactControlHeight,
    required this.iconMd,
    required this.iconSm,
    required this.avatarMd,
    required this.topBarDesktop,
    required this.topBarCompact,
    required this.posHeader,
    required this.posFooter,
    required this.sidebarExpanded,
    required this.sidebarCollapsed,
    required this.contentMaxWidth,
    required this.density,
  });

  /// Surface 0 — background da página.
  final Color bgPrimary;

  /// Surface 1 — sidebar / app bar.
  final Color bgSecondary;

  /// Surface 3 — input / toolbar (elevado face ao card).
  final Color inputBg;

  /// Surface 2 — card / painéis de conteúdo.
  final Color card;
  final Color cardHover;

  /// Surface 4 — dialog / dropdown / menu.
  final Color overlay;

  /// Borda default (~10% opacity).
  final Color border;

  /// Borda subtle (~8% opacity).
  final Color borderSubtle;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color brandBlue;
  final Color brandBlueHover;
  final Color brandGreen;
  final Color brandGreenHover;
  final Color posSuccess;
  final Color posWarning;
  final Color posDanger;
  final Color posInfo;
  final Color psychotropic;
  final Color quarantine;
  final Color incineration;
  final Color recall;
  final double radiusMd;
  final double radiusXl;
  final double radius2xl;
  final double radius3xl;
  final double minTouchTarget;
  final double controlHeight;
  final double compactControlHeight;
  final double iconMd;
  final double iconSm;
  final double avatarMd;
  final double topBarDesktop;
  final double topBarCompact;
  final double posHeader;
  final double posFooter;
  final double sidebarExpanded;
  final double sidebarCollapsed;
  final double contentMaxWidth;
  final DensityTokens density;

  // Aliases semânticos da escala de superfícies (0–4).
  Color get surface0 => bgPrimary;
  Color get surface1 => bgSecondary;
  Color get surface2 => card;
  Color get surface3 => inputBg;
  Color get surface4 => overlay;

  // Radius canónico: sm=4, md=8, lg=10.
  double get radiusSm => RadiusTokens.sm;
  double get radiusLg => radiusXl;

  static PharmaTokens enterpriseDark({DensityTokens density = DensityTokens.comfortable}) {
    return PharmaTokens(
      bgPrimary: AppColorsDark.surface0,
      bgSecondary: AppColorsDark.surface1,
      card: AppColorsDark.surface2,
      cardHover: Color.alphaBlend(
        Colors.white.withValues(alpha: 0.03),
        AppColorsDark.surface2,
      ),
      inputBg: AppColorsDark.surface3,
      overlay: AppColorsDark.surface4,
      border: AppColorsDark.border,
      borderSubtle: AppColorsDark.borderSubtle,
      textPrimary: AppColorsDark.textPrimary,
      textSecondary: AppColorsDark.textSecondary,
      textMuted: AppColorsDark.textSecondary,
      textDisabled: AppColorsDark.textDisabled,
      brandBlue: AppColors.pharmaBlueSoft,
      brandBlueHover: AppColors.pharmaBlue,
      brandGreen: AppColors.hospitalGreenBright,
      brandGreenHover: AppColors.hospitalGreen,
      posSuccess: AppColors.hospitalGreenBright,
      posWarning: AppColors.attention,
      posDanger: AppColors.critical,
      posInfo: AppColors.info,
      psychotropic: const Color(0xFF8B5CF6),
      quarantine: const Color(0xFFFB923C),
      incineration: const Color(0xFFDC2626),
      recall: const Color(0xFFEAB308),
      radiusMd: RadiusTokens.md,
      radiusXl: RadiusTokens.lg,
      radius2xl: RadiusTokens.lg,
      radius3xl: RadiusTokens.lg,
      minTouchTarget: DesignMetrics.minTouchTarget,
      controlHeight: DesignMetrics.controlHeight,
      compactControlHeight: DesignMetrics.compactControlHeight,
      iconMd: DesignMetrics.iconMd,
      iconSm: DesignMetrics.iconSm,
      avatarMd: DesignMetrics.avatarMd,
      topBarDesktop: DesignMetrics.topBarDesktop,
      topBarCompact: DesignMetrics.topBarCompact,
      posHeader: DesignMetrics.posHeader,
      posFooter: DesignMetrics.posFooter,
      sidebarExpanded: DesignMetrics.sidebarExpanded,
      sidebarCollapsed: DesignMetrics.sidebarCollapsed,
      contentMaxWidth: DesignMetrics.contentMaxWidth,
      density: density,
    );
  }

  static PharmaTokens enterpriseLight({DensityTokens density = DensityTokens.comfortable}) {
    return PharmaTokens(
      bgPrimary: AppColorsLight.surface0,
      bgSecondary: AppColorsLight.surface1,
      card: AppColorsLight.surface2,
      cardHover: Color.alphaBlend(
        Colors.black.withValues(alpha: 0.02),
        AppColorsLight.surface2,
      ),
      inputBg: AppColorsLight.surface3,
      overlay: AppColorsLight.surface4,
      border: AppColorsLight.border,
      borderSubtle: AppColorsLight.borderSubtle,
      textPrimary: AppColorsLight.textPrimary,
      textSecondary: AppColorsLight.textSecondary,
      textMuted: AppColorsLight.textSecondary,
      textDisabled: AppColorsLight.textDisabled,
      brandBlue: AppColors.pharmaBlue,
      brandBlueHover: AppColors.pharmaBlueDeep,
      brandGreen: AppColors.hospitalGreen,
      brandGreenHover: const Color(0xFF047857),
      posSuccess: AppColors.success,
      posWarning: AppColors.attention,
      posDanger: AppColors.critical,
      posInfo: AppColors.info,
      psychotropic: const Color(0xFF7C3AED),
      quarantine: const Color(0xFFEA580C),
      incineration: const Color(0xFFB91C1C),
      recall: const Color(0xFFCA8A04),
      radiusMd: RadiusTokens.md,
      radiusXl: RadiusTokens.lg,
      radius2xl: RadiusTokens.lg,
      radius3xl: RadiusTokens.lg,
      minTouchTarget: DesignMetrics.minTouchTarget,
      controlHeight: DesignMetrics.controlHeight,
      compactControlHeight: DesignMetrics.compactControlHeight,
      iconMd: DesignMetrics.iconMd,
      iconSm: DesignMetrics.iconSm,
      avatarMd: DesignMetrics.avatarMd,
      topBarDesktop: DesignMetrics.topBarDesktop,
      topBarCompact: DesignMetrics.topBarCompact,
      posHeader: DesignMetrics.posHeader,
      posFooter: DesignMetrics.posFooter,
      sidebarExpanded: DesignMetrics.sidebarExpanded,
      sidebarCollapsed: DesignMetrics.sidebarCollapsed,
      contentMaxWidth: DesignMetrics.contentMaxWidth,
      density: density,
    );
  }

  @override
  PharmaTokens copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? inputBg,
    Color? card,
    Color? cardHover,
    Color? overlay,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? brandBlue,
    Color? brandBlueHover,
    Color? brandGreen,
    Color? brandGreenHover,
    Color? posSuccess,
    Color? posWarning,
    Color? posDanger,
    Color? posInfo,
    Color? psychotropic,
    Color? quarantine,
    Color? incineration,
    Color? recall,
    double? radiusMd,
    double? radiusXl,
    double? radius2xl,
    double? radius3xl,
    double? minTouchTarget,
    double? controlHeight,
    double? compactControlHeight,
    double? iconMd,
    double? iconSm,
    double? avatarMd,
    double? topBarDesktop,
    double? topBarCompact,
    double? posHeader,
    double? posFooter,
    double? sidebarExpanded,
    double? sidebarCollapsed,
    double? contentMaxWidth,
    DensityTokens? density,
  }) {
    return PharmaTokens(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      inputBg: inputBg ?? this.inputBg,
      card: card ?? this.card,
      cardHover: cardHover ?? this.cardHover,
      overlay: overlay ?? this.overlay,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      brandBlue: brandBlue ?? this.brandBlue,
      brandBlueHover: brandBlueHover ?? this.brandBlueHover,
      brandGreen: brandGreen ?? this.brandGreen,
      brandGreenHover: brandGreenHover ?? this.brandGreenHover,
      posSuccess: posSuccess ?? this.posSuccess,
      posWarning: posWarning ?? this.posWarning,
      posDanger: posDanger ?? this.posDanger,
      posInfo: posInfo ?? this.posInfo,
      psychotropic: psychotropic ?? this.psychotropic,
      quarantine: quarantine ?? this.quarantine,
      incineration: incineration ?? this.incineration,
      recall: recall ?? this.recall,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusXl: radiusXl ?? this.radiusXl,
      radius2xl: radius2xl ?? this.radius2xl,
      radius3xl: radius3xl ?? this.radius3xl,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      controlHeight: controlHeight ?? this.controlHeight,
      compactControlHeight: compactControlHeight ?? this.compactControlHeight,
      iconMd: iconMd ?? this.iconMd,
      iconSm: iconSm ?? this.iconSm,
      avatarMd: avatarMd ?? this.avatarMd,
      topBarDesktop: topBarDesktop ?? this.topBarDesktop,
      topBarCompact: topBarCompact ?? this.topBarCompact,
      posHeader: posHeader ?? this.posHeader,
      posFooter: posFooter ?? this.posFooter,
      sidebarExpanded: sidebarExpanded ?? this.sidebarExpanded,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      density: density ?? this.density,
    );
  }

  @override
  PharmaTokens lerp(ThemeExtension<PharmaTokens>? other, double t) {
    if (other is! PharmaTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension PharmaTokensX on BuildContext {
  PharmaTokens get pharmaTokens {
    final extension = Theme.of(this).extension<PharmaTokens>();
    if (extension != null) return extension;
    return Theme.of(this).brightness == Brightness.dark
        ? PharmaTokens.enterpriseDark()
        : PharmaTokens.enterpriseLight();
  }
}

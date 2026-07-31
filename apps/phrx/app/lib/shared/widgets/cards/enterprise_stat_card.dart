import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_surface.dart';

/// Densidade visual do KPI (balcão / tablet compacto / desktop).
enum StatCardDensity {
  /// Menos altura, tipografia compacta — mobile e tablet operacional.
  compact,

  /// Área de leitura ligeiramente maior — desktop ou destaques.
  comfortable,
}

/// Cartão KPI enterprise — hierarquia clara, toque com ripple, hover no desktop.
class EnterpriseStatCard extends StatelessWidget {
  const EnterpriseStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accent = StatCardAccent.neutral,
    this.density = StatCardDensity.compact,
    this.onTap,
    this.badge,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final StatCardAccent accent;
  final StatCardDensity density;
  final VoidCallback? onTap;
  /// Texto curto opcional (ex.: LIVE, SYNC).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final colors = context.colors;
    final textTheme = context.typography;
    final s = context.spacing;
    final compact = density == StatCardDensity.compact;
    final (Color fg, Color bg) = switch (accent) {
      StatCardAccent.positive => (t.posSuccess, colors.successSubtle),
      StatCardAccent.warning => (t.posWarning, colors.warningSubtle),
      StatCardAccent.danger => (t.posDanger, colors.errorSubtle),
      StatCardAccent.info => (t.posInfo, colors.infoSubtle),
      StatCardAccent.neutral => (t.textSecondary, colors.neutralSubtle),
    };

    final pad = compact
        ? EdgeInsets.fromLTRB(s.sm, s.sm, s.sm, s.sm)
        : EdgeInsets.all(s.lg);
    final iconBox = compact ? s.xs : s.sm;
    final iconSize = compact ? DesignMetrics.iconSm : t.iconSm;
    final gapAfterHeader = compact ? s.xs : s.md;
    final gapBeforeSubtitle = compact ? s.xxs : s.sm;
    final titleStyle = AppTypography.kpiLabel(textTheme, compact: compact).copyWith(
      color: t.textMuted,
    );
    final valueStyle = AppTypography.kpiValue(textTheme, compact: compact).copyWith(
      letterSpacing: -0.3,
      height: 1.0,
      color: accent == StatCardAccent.danger ? t.posDanger : t.textPrimary,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            if (badge != null)
              Padding(
                padding: EdgeInsets.only(right: s.xs),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: s.xs, vertical: s.xxs),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(t.radiusSm),
                  ),
                  child: Text(
                    badge!,
                    style: textTheme.erpOverline.copyWith(color: fg),
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.all(iconBox),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(t.radiusMd),
              ),
              child: Icon(icon, size: iconSize, color: fg),
            ),
          ],
        ),
        SizedBox(height: gapAfterHeader),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: gapBeforeSubtitle),
          Text(
            subtitle!,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.erpCaption.copyWith(color: t.textMuted, height: 1.1),
          ),
        ],
      ],
    );

    return PharmaSurface(
      color: t.surface2,
      padding: pad,
      onTap: onTap,
      hoverColor: onTap != null ? t.cardHover : null,
      splashColor: onTap != null ? t.surface3 : null,
      child: content,
    );
  }
}

enum StatCardAccent { neutral, positive, warning, danger, info }

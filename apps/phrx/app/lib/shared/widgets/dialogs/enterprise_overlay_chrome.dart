import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Acções full-width em ecrãs estreitos: mesma linha se couberem; senão wrap.
class EnterpriseResponsiveActions extends StatelessWidget {
  const EnterpriseResponsiveActions({
    super.key,
    required this.actions,
    this.spacing,
    this.alignment = WrapAlignment.start,
    this.forceExpand = false,
  });

  final List<Widget> actions;
  final double? spacing;
  final WrapAlignment alignment;

  /// Quando true, força expansão (ex.: mobile), independentemente da largura.
  final bool forceExpand;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final s = context.spacing;
    final gap = spacing ?? s.sm;
    final t = context.pharmaTokens;
    final expand = forceExpand ||
        MediaQuery.sizeOf(context).width < Breakpoints.tablet;

    if (!expand) {
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final action in actions)
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: t.minTouchTarget,
                minWidth: DesignMetrics.overlayActionMinWidth,
              ),
              child: action,
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final count = actions.length;
        final totalGaps = gap * (count - 1);
        final equalWidth = count > 0 ? (maxWidth - totalGaps) / count : maxWidth;
        final fitSameLine =
            equalWidth >= DesignMetrics.overlayActionMinWidth;

        if (fitSameLine) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: t.minTouchTarget),
                      child: actions[i],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              SizedBox(
                width: maxWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: t.minTouchTarget),
                  child: action,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Cabeçalho padronizado: título, subtítulo opcional, ícone e fechar.
class EnterpriseOverlayHeader extends StatelessWidget {
  const EnterpriseOverlayHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onClose,
    this.showClose = true,
  });

  final Widget title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.sm, s.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: t.iconMd, color: t.textSecondary),
            SizedBox(width: s.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(
                  style: theme.textTheme.erpCardTitle.copyWith(
                    color: t.textPrimary,
                  ),
                  child: title,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: s.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.erpBodySecondary.copyWith(
                      color: t.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showClose)
            IconButton(
              tooltip: 'Fechar',
              onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.close_rounded, color: t.textMuted, size: t.iconMd),
            ),
        ],
      ),
    );
  }
}

/// Rodapé padronizado — botões à direita, min-width tokenizada, gap 12px.
class EnterpriseOverlayFooter extends StatelessWidget {
  const EnterpriseOverlayFooter({
    super.key,
    required this.actions,
    this.dense = false,
    this.expandOnNarrow = true,
  });

  final List<Widget> actions;
  final bool dense;
  final bool expandOnNarrow;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final t = context.pharmaTokens;
    final s = context.spacing;
    // 12px entre botões ([SpacingTokens.md]).
    final gap = s.md;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border(
          top: BorderSide(
            color: t.borderSubtle,
            width: BorderTokens.width,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            s.lg,
            dense ? s.md : s.lg,
            s.lg,
            dense ? s.md : s.lg,
          ),
          child: EnterpriseResponsiveActions(
            actions: actions,
            spacing: gap,
            alignment: WrapAlignment.end,
            forceExpand: expandOnNarrow &&
                MediaQuery.sizeOf(context).width < Breakpoints.tablet,
          ),
        ),
      ),
    );
  }
}

/// Helpers de botões de rodapé (primária / secundária / destrutiva).
abstract final class EnterpriseOverlayActions {
  EnterpriseOverlayActions._();

  static Widget secondary({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  static Widget primary({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  static Widget destructive({
    required BuildContext context,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final t = context.pharmaTokens;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: t.posDanger),
      child: Text(label),
    );
  }
}

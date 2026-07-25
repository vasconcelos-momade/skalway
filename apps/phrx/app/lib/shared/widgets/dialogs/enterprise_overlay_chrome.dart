import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

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

/// Rodapé padronizado com ações alinhadas ao Design System.
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
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.tablet;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        s.lg,
        dense ? s.sm : s.md,
        s.lg,
        dense ? s.md : s.lg,
      ),
      child: narrow && expandOnNarrow
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) SizedBox(width: s.sm),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: t.minTouchTarget),
                        child: actions[i],
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Wrap(
              spacing: s.sm,
              runSpacing: s.sm,
              alignment: WrapAlignment.end,
              children: [
                for (final action in actions)
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: t.minTouchTarget),
                    child: action,
                  ),
              ],
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

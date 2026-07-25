import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Divisor horizontal padrão para listas operacionais mobile (1dp, margem 12–16).
class EnterpriseListDivider extends StatelessWidget {
  const EnterpriseListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final dividerTheme = DividerTheme.of(context);
    final s = context.spacing;

    return Divider(
      height: 1,
      thickness: 1,
      indent: s.md,
      endIndent: s.md,
      color: dividerTheme.color,
    );
  }
}

/// Item de listagem operacional mobile — sem card, sombra ou elevação.
class EnterpriseListCard extends StatelessWidget {
  const EnterpriseListCard({
    super.key,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.trailing,
    this.chip,
    this.metadata = const [],
    this.trailingMeta,
    this.onTap,
    this.actions,
    this.isBusy = false,
  });

  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final IconData? leading;
  final Widget? trailing;
  final Widget? chip;
  final List<EnterpriseListCardMeta> metadata;
  final EnterpriseListCardMeta? trailingMeta;
  final VoidCallback? onTap;
  final Widget? actions;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final hasTrailingColumn =
        chip != null || actions != null || trailing != null || isBusy || trailingMeta != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.lg, vertical: s.sm),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[
                  Icon(leading, size: t.iconMd, color: t.textSecondary),
                  SizedBox(width: s.md),
                ],
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (titleWidget != null)
                              titleWidget!
                            else
                              Text(
                                title,
                                style: theme.textTheme.erpCardTitle.copyWith(
                                  color: t.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (subtitle != null) ...[
                              SizedBox(height: s.xxs),
                              Text(
                                subtitle!,
                                style: theme.textTheme.erpBodySecondary.copyWith(
                                  color: t.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (metadata.isNotEmpty) ...[
                              SizedBox(height: s.xxs),
                              for (var i = 0; i < metadata.length; i++) ...[
                                if (i > 0) SizedBox(height: s.xxs),
                                _MetaRow(meta: metadata[i]),
                              ],
                            ],
                          ],
                        ),
                      ),
                      if (hasTrailingColumn) ...[
                        SizedBox(width: s.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chip != null || actions != null || trailing != null || isBusy)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ?chip,
                                  if (chip != null &&
                                      (actions != null || trailing != null || isBusy))
                                    SizedBox(width: s.xxs),
                                  if (isBusy)
                                    SizedBox(
                                      width: DesignMetrics.iconMd,
                                      height: DesignMetrics.iconMd,
                                      child: CircularProgressIndicator(
                                        strokeWidth: DesignMetrics.buttonLoaderStrokeWidth,
                                      ),
                                    )
                                  else if (actions != null)
                                    actions!
                                  else ?trailing,
                                ],
                              ),
                            if (trailingMeta != null) ...[
                              const Spacer(),
                              _MetaRow(meta: trailingMeta!),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EnterpriseListCardMeta {
  const EnterpriseListCardMeta({
    required this.label,
    this.color,
    this.alignEnd = false,
    this.emphasized = false,
  });

  final String label;
  final Color? color;
  final bool alignEnd;
  final bool emphasized;
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.meta});

  final EnterpriseListCardMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return Text(
      meta.label,
      textAlign: meta.alignEnd ? TextAlign.end : TextAlign.start,
      style: Theme.of(context).textTheme.erpCaption.copyWith(
            color: meta.color ?? t.textMuted,
            fontWeight: meta.emphasized ? FontWeight.w600 : FontWeight.w400,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Chip de estado para listagens operacionais mobile.
class EnterpriseStatusChip extends StatelessWidget {
  const EnterpriseStatusChip({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final resolved = color ?? t.textMuted;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusScale.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.erpLabel.copyWith(color: resolved),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/extensions.dart';

/// Agrupa conteúdo de uma secção com título e card M3.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.erpSectionTitle.copyWith(
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: s.sm),
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            elevation: 0,
            borderRadius: BorderRadius.circular(t.radiusMd),
            child: Padding(
              padding: EdgeInsets.all(s.md),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

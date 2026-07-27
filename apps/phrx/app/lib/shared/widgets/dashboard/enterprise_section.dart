import 'package:flutter/material.dart';

import '../../../core/theme/extensions.dart';

class EnterpriseSection extends StatelessWidget {
  const EnterpriseSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = context.typography;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.erpSectionTitle.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (action != null) ...[
              SizedBox(width: s.md),
              action!,
            ],
          ],
        ),
        SizedBox(height: s.md),
        child,
      ],
    );
  }
}

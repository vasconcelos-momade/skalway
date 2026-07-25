import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';

class DetailSection extends StatelessWidget {
  const DetailSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: s.md),
          ...children,
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: s.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: Theme.of(
                context,
              ).textTheme.erpBodyStrong.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailHint extends StatelessWidget {
  const DetailHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Padding(
      padding: EdgeInsets.only(top: s.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.erpCaption.copyWith(
          color: t.textMuted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

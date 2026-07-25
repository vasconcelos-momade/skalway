import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Blocos skeleton para listagens e cartões.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius});

  final double? width;
  final double? height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final resolvedHeight = height ?? SpacingTokens.sm;
    final resolvedRadius = radius ?? t.radiusMd;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.85),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, v, child) {
        return Container(
          width: width,
          height: resolvedHeight,
          decoration: BoxDecoration(
            color: t.border.withValues(alpha: v),
            borderRadius: BorderRadius.circular(resolvedRadius),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      padding: SpacingTokens.cardPadding,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: s.sm),
          SizedBox(height: s.lg),
          SkeletonBox(width: double.infinity, height: s.xl),
          SizedBox(height: s.md),
          SkeletonBox(width: 200, height: s.sm),
        ],
      ),
    );
  }
}

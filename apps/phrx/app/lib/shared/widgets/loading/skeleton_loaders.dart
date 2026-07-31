import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';

/// Blocos skeleton suaves — sem bordas, sem escurecimento.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius});

  final double? width;
  final double? height;
  final double? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.slow * 2,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedHeight = widget.height ?? SpacingTokens.sm;
    final resolvedRadius = widget.radius ?? t.radiusMd;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = _controller.value;
        final fill = Color.alphaBlend(
          t.textPrimary.withValues(
            alpha: isDark ? 0.06 + pulse * 0.05 : 0.04 + pulse * 0.03,
          ),
          t.surface2,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(resolvedRadius),
          ),
          child: SizedBox(
            width: widget.width,
            height: resolvedHeight,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Padding(
        padding: SpacingTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: SpacingTokens.xxxl * 3, height: s.sm),
            SizedBox(height: s.lg),
            const SkeletonBox(width: double.infinity, height: SpacingTokens.xl),
            SizedBox(height: s.md),
            SkeletonBox(width: SpacingTokens.xxxl * 5, height: s.sm),
          ],
        ),
      ),
    );
  }
}

/// Linha skeleton de tabela — sem borda, altura de linha do DS.
class SkeletonTableRow extends StatelessWidget {
  const SkeletonTableRow({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return SkeletonBox(
      width: double.infinity,
      height: height ?? DesignMetrics.tableRowHeightMax,
      radius: t.radiusMd,
    );
  }
}

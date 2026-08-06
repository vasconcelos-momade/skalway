import 'package:flutter/material.dart';

import '../../../core/theme/extensions.dart';

/// Grid responsivo para formulários enterprise (1 col mobile, 2 cols tablet+).
class EnterpriseFormGrid extends StatelessWidget {
  const EnterpriseFormGrid({
    super.key,
    required this.children,
    this.gap,
  });

  final List<EnterpriseFormGridItem> children;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final spacing = gap ?? context.spacing.md;
    final columns = context.isMobile ? 1 : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = spacing * (columns - 1);
        final colWidth = (constraints.maxWidth - totalGap) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in children)
              SizedBox(
                width: item.fullWidth || columns == 1
                    ? constraints.maxWidth
                    : colWidth,
                child: item.child,
              ),
          ],
        );
      },
    );
  }
}

class EnterpriseFormGridItem {
  const EnterpriseFormGridItem({
    required this.child,
    this.fullWidth = false,
  });

  final Widget child;
  final bool fullWidth;
}

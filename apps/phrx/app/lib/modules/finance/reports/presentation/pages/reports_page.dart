import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/layout/module_page_frame.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return ModulePageFrame(
      title: 'RELATÓRIOS AVANÇADOS',
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: t.card.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.border, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: t.textMuted),
            const SizedBox(height: 16),
            Text(
              'CENTRO DE RELATÓRIOS',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpOverline.copyWith(
                    color: t.textSecondary,
                    letterSpacing: 3,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'BI • Analytics sanitário • Performance de vendas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

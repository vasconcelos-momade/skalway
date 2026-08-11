import 'package:flutter/material.dart';

import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_surface.dart';

enum EnterpriseAlertSeverity { info, warning, error, success }

class EnterpriseAlertCard extends StatelessWidget {
  const EnterpriseAlertCard({
    super.key,
    required this.title,
    required this.description,
    this.severity = EnterpriseAlertSeverity.warning,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String description;
  final EnterpriseAlertSeverity severity;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = context.typography;
    final s = context.spacing;

    final (Color color, IconData icon) = switch (severity) {
      EnterpriseAlertSeverity.info => (t.brandBlue, Icons.info_outline),
      EnterpriseAlertSeverity.warning => (t.posWarning, Icons.warning_amber_rounded),
      EnterpriseAlertSeverity.error => (t.posDanger, Icons.error_outline),
      EnterpriseAlertSeverity.success => (t.posSuccess, Icons.check_circle_outline),
    };

    return PharmaSurface(
      padding: EdgeInsets.all(s.md),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      color: color.withValues(alpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: t.iconMd),
          SizedBox(width: s.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.erpCardTitle.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: s.xxs),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.erpBody.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
          if (actionText != null && onAction != null) ...[
            SizedBox(width: s.md),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}

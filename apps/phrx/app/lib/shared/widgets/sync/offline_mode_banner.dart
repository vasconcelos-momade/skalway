import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

class OfflineModeBanner extends StatelessWidget {
  const OfflineModeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Material(
      color: t.posWarning.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: s.lg, vertical: s.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.posWarning.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: t.posWarning,
                size: t.iconSm,
              ),
              SizedBox(width: s.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.erpBodyStrong.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

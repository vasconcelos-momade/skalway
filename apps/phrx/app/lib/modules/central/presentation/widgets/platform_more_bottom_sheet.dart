import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_metrics.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../navigation/platform_nav_config.dart';

/// Bottom Sheet "Mais" do Painel Admin (mobile).
Future<void> showPlatformMoreBottomSheet(BuildContext context) {
  final items = platformMoreNavItems();
  final t = context.pharmaTokens;
  final s = context.spacing;
  final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: t.surface1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusXl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(s.md, 0, s.md, s.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Mais módulos',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: s.sm),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: t.border),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Icon(
                          item.icon,
                          size: DesignMetrics.iconMd,
                          color: t.textSecondary,
                        ),
                        title: Text(
                          item.label,
                          style:
                              Theme.of(context).textTheme.erpMenuItem.copyWith(
                                    color: t.textPrimary,
                                  ),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          context.go(item.path);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

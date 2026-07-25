import 'package:flutter/material.dart';

import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/extensions.dart';

/// Propriedade com título pequeno e valor destacado (Material 3).
class PropertyTile extends StatefulWidget {
  const PropertyTile({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 3,
    this.expandable = true,
  });

  final String label;
  final String? value;
  final int maxLines;
  final bool expandable;

  @override
  State<PropertyTile> createState() => _PropertyTileState();
}

class _PropertyTileState extends State<PropertyTile> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final theme = Theme.of(context);
    final display = widget.value?.trim().isEmpty ?? true ? '—' : widget.value!.trim();
    final needsExpand = widget.expandable && display.length > 80;

    return Padding(
      padding: EdgeInsets.only(bottom: s.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: theme.textTheme.erpCaption.copyWith(
              color: t.textMuted,
            ),
          ),
          SizedBox(height: s.xs),
          Text(
            display,
            maxLines: _expanded ? null : widget.maxLines,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: theme.textTheme.erpBody.copyWith(
              color: t.textPrimary,
            ),
          ),
          if (needsExpand && !_expanded)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _expanded = true),
              child: const Text('Ver mais'),
            ),
        ],
      ),
    );
  }
}

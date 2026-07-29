import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import 'enterprise_dropdown_menu.dart';

/// Botão ⋮ da coluna Acções — abre [EnterpriseDropdownMenu] com Design Tokens.
class EnterpriseActionsMenuButton<T> extends StatelessWidget {
  const EnterpriseActionsMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.tooltip = 'Acções',
    this.icon = Icons.more_vert_rounded,
    this.compact = false,
    this.enabled = true,
    this.width,
  });

  final List<EnterpriseDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final IconData icon;
  final bool compact;
  final bool enabled;
  final double? width;

  Future<void> _open(BuildContext context, BuildContext anchorContext) async {
    if (!enabled || items.isEmpty) return;
    final selected = await showEnterpriseDropdownMenuFrom<T>(
      context: context,
      anchorContext: anchorContext,
      items: items,
      width: width,
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final size = compact ? t.iconSm : t.iconMd;

    return Builder(
      builder: (anchorContext) {
        return IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: compact
              ? BoxConstraints(
                  minWidth: t.minTouchTarget * 0.6,
                  minHeight: t.minTouchTarget * 0.6,
                )
              : null,
          onPressed: enabled ? () => _open(context, anchorContext) : null,
          icon: Icon(icon, size: size, color: t.textMuted),
        );
      },
    );
  }
}

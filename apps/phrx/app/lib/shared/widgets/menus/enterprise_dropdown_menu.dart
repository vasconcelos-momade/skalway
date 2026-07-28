import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/shadows.dart';

/// Item de menu para [EnterpriseDropdownMenu].
class EnterpriseDropdownItem<T> {
  const EnterpriseDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.selected = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool selected;
}

/// Menu dropdown enterprise — superfície elevada, borda e sombra via Design Tokens.
class EnterpriseDropdownMenu<T> extends StatelessWidget {
  const EnterpriseDropdownMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.width,
  });

  final List<EnterpriseDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final elevation = context.elevationTokens;

    return Material(
      color: Colors.transparent,
      elevation: elevation.level2,
      shadowColor: t.textPrimary.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Container(
        width: width,
        constraints: BoxConstraints(minWidth: width ?? 200),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(color: t.border, width: 1),
          boxShadow: ShadowScale.sm,
        ),
        padding: EdgeInsets.symmetric(vertical: s.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              _EnterpriseDropdownTile<T>(
                item: item,
                onSelected: onSelected,
                tokens: t,
                spacing: s,
                textTheme: textTheme,
              ),
          ],
        ),
      ),
    );
  }
}

class _EnterpriseDropdownTile<T> extends StatefulWidget {
  const _EnterpriseDropdownTile({
    required this.item,
    required this.onSelected,
    required this.tokens,
    required this.spacing,
    required this.textTheme,
  });

  final EnterpriseDropdownItem<T> item;
  final ValueChanged<T> onSelected;
  final PharmaTokens tokens;
  final DensityTokens spacing;
  final TextTheme textTheme;

  @override
  State<_EnterpriseDropdownTile<T>> createState() =>
      _EnterpriseDropdownTileState<T>();
}

class _EnterpriseDropdownTileState<T> extends State<_EnterpriseDropdownTile<T>> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final s = widget.spacing;
    final enabled = widget.item.enabled;
    final selected = widget.item.selected;

    Color? background;
    if (!enabled) {
      background = null;
    } else if (_pressed) {
      background = t.cardHover;
    } else if (_hovered || _focused || selected) {
      background = t.bgSecondary;
    }

    final foreground = !enabled
        ? t.textMuted.withValues(alpha: 0.5)
        : selected
            ? t.brandBlue
            : t.textPrimary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onSelected(widget.item.value);
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: enabled
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onSelected(widget.item.value);
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            constraints: BoxConstraints(minHeight: t.controlHeight),
            padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
            color: background,
            child: Row(
              children: [
                if (widget.item.icon != null) ...[
                  Icon(widget.item.icon, size: t.iconSm, color: foreground),
                  SizedBox(width: s.sm),
                ],
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: widget.textTheme.erpBodySecondary.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: t.iconSm, color: t.brandBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mostra [EnterpriseDropdownMenu] ancorado via [RelativeRect].
Future<T?> showEnterpriseDropdownMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<EnterpriseDropdownItem<T>> items,
  double width = 220,
}) {
  final completer = Completer<T?>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                entry.remove();
                if (!completer.isCompleted) completer.complete(null);
              },
            ),
          ),
          CustomSingleChildLayout(
            delegate: _DropdownMenuLayout(position),
            child: EnterpriseDropdownMenu<T>(
              width: width,
              items: items,
              onSelected: (value) {
                entry.remove();
                if (!completer.isCompleted) completer.complete(value);
              },
            ),
          ),
        ],
      );
    },
  );

  Overlay.of(context).insert(entry);
  return completer.future;
}

class _DropdownMenuLayout extends SingleChildLayoutDelegate {
  _DropdownMenuLayout(this.position);

  final RelativeRect position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = position.left;
    var y = size.height - position.bottom;
    if (x + childSize.width > size.width) {
      x = size.width - childSize.width - 8;
    }
    if (y + childSize.height > size.height) {
      y = position.top - childSize.height;
    }
    return Offset(
      x.clamp(0, size.width - childSize.width),
      y.clamp(0.0, size.height),
    );
  }

  @override
  bool shouldRelayout(covariant _DropdownMenuLayout oldDelegate) =>
      position != oldDelegate.position;
}

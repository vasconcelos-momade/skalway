import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_border_tokens.dart';
import '../../../core/theme/pharma_color_tokens.dart' hide PharmaColorTokensX;

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
///
/// Estilização centralizada para reutilização (tema claro/escuro consistente).
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
    final colors = context.colors;
    final borders = context.borders;
    final textTheme = Theme.of(context).textTheme;
    final elevation = context.elevationTokens;
    final shadows = context.shadows;
    final widths = context.widths;
    final radius = BorderRadius.circular(t.radiusMd);
    final menuWidth = width ?? widths.dropdownMenu;

    return Material(
      color: Colors.transparent,
      elevation: elevation.level2,
      shadowColor: colors.overlay,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: menuWidth,
        constraints: BoxConstraints(
          minWidth: widths.dropdownMenuMin,
          maxWidth: menuWidth,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: radius,
          border: Border.all(color: t.border, width: borders.borderThin),
          boxShadow: shadows.sm,
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
                colors: colors,
                borders: borders,
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
    required this.colors,
    required this.borders,
    required this.spacing,
    required this.textTheme,
  });

  final EnterpriseDropdownItem<T> item;
  final ValueChanged<T> onSelected;
  final PharmaTokens tokens;
  final PharmaColorTokens colors;
  final PharmaBorderTokens borders;
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
    final colors = widget.colors;
    final borders = widget.borders;
    final s = widget.spacing;
    final enabled = widget.item.enabled;
    final selected = widget.item.selected;
    final motion = context.motion;

    Color? background;
    if (!enabled) {
      background = null;
    } else if (_pressed) {
      background = colors.pressed;
    } else if (_focused) {
      background = colors.focused;
    } else if (_hovered) {
      background = colors.hover;
    } else if (selected) {
      background = colors.selected;
    }

    final foreground = !enabled
        ? colors.neutral
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
            duration: motion.durationFast,
            curve: motion.easeOut,
            constraints: BoxConstraints(minHeight: t.controlHeight),
            padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
            decoration: BoxDecoration(
              color: background,
              border: _focused && enabled
                  ? Border(
                      left: BorderSide(
                        color: t.brandBlue,
                        width: borders.focusBorder,
                      ),
                    )
                  : null,
            ),
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
  double? width,
}) {
  final completer = Completer<T?>();
  late OverlayEntry entry;
  final menuWidth = width ?? context.widths.dropdownMenu;
  final edgeInset = context.spacing.sm;

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
            delegate: _DropdownMenuLayout(position, edgeInset),
            child: EnterpriseDropdownMenu<T>(
              width: menuWidth,
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
  _DropdownMenuLayout(this.position, this.edgeInset);

  final RelativeRect position;
  final double edgeInset;

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
      x = size.width - childSize.width - edgeInset;
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
      position != oldDelegate.position || edgeInset != oldDelegate.edgeInset;
}

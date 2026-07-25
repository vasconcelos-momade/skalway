import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Opção de um [EnterpriseSelectField].
class EnterpriseSelectOption<T> {
  const EnterpriseSelectOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

/// Select enterprise alinhado ao design system / search do PDV:
/// - mesma altura dos inputs (`DesignMetrics.fieldHeightMin` + `inputPadding`)
/// - hover cinza **dentro** do campo
/// - menu abre **abaixo** do input ([MenuAnchor])
class EnterpriseSelectField<T> extends StatefulWidget {
  const EnterpriseSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.emptyLabel,
    this.width,
    this.menuMaxHeight,
    this.enabled = true,
  });

  final String label;
  final List<EnterpriseSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;

  /// Se definido, adiciona opção vazia que chama [onChanged] com `null`.
  final String? emptyLabel;
  final double? width;

  /// Altura máxima do menu. Por omissão: [DesignMetrics.dialogSizeSmall].
  final double? menuMaxHeight;
  final bool enabled;

  @override
  State<EnterpriseSelectField<T>> createState() =>
      _EnterpriseSelectFieldState<T>();
}

class _EnterpriseSelectFieldState<T> extends State<EnterpriseSelectField<T>> {
  bool _hovering = false;

  bool get _hasValue {
    final value = widget.value;
    if (value == null) return false;
    return widget.options.any((option) => option.value == value);
  }

  String get _displayLabel {
    if (!_hasValue) {
      return widget.emptyLabel ?? '';
    }
    return widget.options
        .firstWhere((option) => option.value == widget.value)
        .label;
  }

  /// Com texto visível (incl. "Todas"), o label deve flutuar na borda —
  /// senão label e valor sobrepõem-se no centro do campo.
  bool get _isEmpty => _displayLabel.isEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final enabled = widget.enabled && widget.onChanged != null;
    final inputTheme = theme.inputDecorationTheme;
    final menuMaxHeight =
        widget.menuMaxHeight ?? DesignMetrics.dialogSizeSmall;

    final outline = BorderSide(
      color: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.85),
    );

    final field = LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : widget.width;

        return MenuAnchor(
          consumeOutsideTap: true,
          style: MenuStyle(
            alignment: AlignmentDirectional.bottomStart,
            backgroundColor:
                WidgetStatePropertyAll(scheme.surfaceContainerHighest),
            maximumSize: WidgetStatePropertyAll(
              Size(double.infinity, menuMaxHeight),
            ),
            minimumSize: menuWidth == null
                ? null
                : WidgetStatePropertyAll(Size(menuWidth, 0)),
          ),
          builder: (context, controller, child) {
            final open = controller.isOpen;
            final showHover = enabled && (_hovering || open);

            // Decoração alinhada ao EnterpriseSearchField + InputDecorationTheme.
            final decoration = InputDecoration(
              labelText: widget.label,
              isDense: true,
              filled: inputTheme.filled,
              fillColor: inputTheme.fillColor,
              hoverColor:
                  scheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.06),
              contentPadding:
                  inputTheme.contentPadding ?? t.density.inputPadding,
              constraints: inputTheme.constraints ??
                  BoxConstraints(
                    minHeight: t.minTouchTarget,
                  ),
              labelStyle: inputTheme.labelStyle ??
                  textTheme.erpSelectLabel.copyWith(color: t.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: outline,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: outline,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: BorderSide(color: scheme.primary),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusMd),
                borderSide: outline,
              ),
              suffixIcon: Icon(
                open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: t.iconSm,
                color: enabled ? t.textSecondary : t.textMuted,
              ),
            );

            return MouseRegion(
              cursor: enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: enabled ? (_) => setState(() => _hovering = true) : null,
              onExit: enabled ? (_) => setState(() => _hovering = false) : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: !enabled
                    ? null
                    : () {
                        if (open) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                child: InputDecorator(
                  isFocused: open,
                  isHovering: showHover,
                  isEmpty: _isEmpty,
                  decoration: decoration,
                  child: Text(
                    _displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.erpBody.copyWith(
                      color: enabled ? t.textPrimary : t.textMuted,
                    ),
                  ),
                ),
              ),
            );
          },
          menuChildren: [
            if (widget.emptyLabel != null)
              MenuItemButton(
                onPressed: !enabled
                    ? null
                    : () {
                        widget.onChanged?.call(null);
                      },
                trailingIcon: !_hasValue
                    ? Icon(Icons.check, size: t.iconSm, color: scheme.primary)
                    : null,
                child: Text(
                  widget.emptyLabel!,
                  style: textTheme.erpBody.copyWith(color: t.textPrimary),
                ),
              ),
            ...widget.options.map(
              (option) => MenuItemButton(
                onPressed: !enabled
                    ? null
                    : () {
                        widget.onChanged?.call(option.value);
                      },
                trailingIcon: _hasValue && option.value == widget.value
                    ? Icon(Icons.check, size: t.iconSm, color: scheme.primary)
                    : null,
                child: Text(
                  option.label,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.erpBody.copyWith(color: t.textPrimary),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.width == null) return field;
    return SizedBox(width: widget.width, child: field);
  }
}

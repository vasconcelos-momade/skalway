import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/typography.dart';
import 'enterprise_field_decoration.dart';

/// Select enterprise alinhado ao design system / search do PDV:
/// - mesma altura dos inputs e botões (`PharmaTokens.controlHeight`)
/// - hover cinza **dentro** do campo
/// - menu abre **abaixo** do input ([MenuAnchor])
class EnterpriseSelectOption<T> {
  const EnterpriseSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

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
    this.prefixIcon,
    this.errorText,
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
  final Widget? prefixIcon;
  final String? errorText;
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
    final colors = context.colors;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final enabled = widget.enabled && widget.onChanged != null;
    final menuMaxHeight = widget.menuMaxHeight ?? DesignMetrics.dialogSizeSmall;

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
            backgroundColor: WidgetStatePropertyAll(t.surface4),
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

            final decoration =
                EnterpriseFieldDecoration.of(
                  context,
                  hintText: widget.emptyLabel ?? 'Selecionar',
                  errorText: widget.errorText,
                  enabled: enabled,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: t.iconMd,
                    color: enabled ? t.textSecondary : t.textMuted,
                  ),
                ).copyWith(
                  hoverColor: colors.fieldHover,
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
                    style: textTheme.erpSelectValue.copyWith(
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
                    ? Icon(
                        Icons.check,
                        size: t.iconSm,
                        color: colors.sidebarActiveIndicator,
                      )
                    : null,
                child: Text(
                  widget.emptyLabel!,
                  style: textTheme.erpBody.copyWith(
                    color: !_hasValue ? t.textPrimary : t.textSecondary,
                    fontWeight: !_hasValue ? FontWeight.w600 : FontWeight.w500,
                  ),
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
                    ? Icon(
                        Icons.check,
                        size: t.iconSm,
                        color: colors.sidebarActiveIndicator,
                      )
                    : null,
                child: Text(
                  option.label,
                  style: textTheme.erpBody.copyWith(
                    color: _hasValue && option.value == widget.value
                        ? t.textPrimary
                        : t.textSecondary,
                    fontWeight: _hasValue && option.value == widget.value
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    final wrapped = widget.width == null ? field : SizedBox(width: widget.width, child: field);
    return EnterpriseFieldGroup(labelText: widget.label, child: wrapped);
  }
}

class EnterpriseSelectFormField<T> extends FormField<T> {
  EnterpriseSelectFormField({
    super.key,
    required String label,
    required List<EnterpriseSelectOption<T>> options,
    required ValueChanged<T?>? onChanged,
    super.initialValue,
    String? emptyLabel,
    double? width,
    double? menuMaxHeight,
    Widget? prefixIcon,
    bool enabled = true,
    super.validator,
    super.autovalidateMode,
  }) : super(
         builder: (field) {
           return EnterpriseSelectField<T>(
             label: label,
             options: options,
             value: field.value,
             emptyLabel: emptyLabel,
             width: width,
             menuMaxHeight: menuMaxHeight,
             prefixIcon: prefixIcon,
             errorText: field.errorText,
             enabled: enabled,
             onChanged: !enabled
                 ? null
                 : (value) {
                     field.didChange(value);
                     onChanged?.call(value);
                   },
           );
         },
       );
}

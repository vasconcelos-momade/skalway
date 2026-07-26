import 'package:flutter/material.dart';

import '../../shared/widgets/inputs/enterprise_select_field.dart';
import 'design_tokens.dart';
import 'extensions.dart';
import 'typography.dart';

/// Duração zero para superfícies Material (evita atraso ao trocar tema).
const Duration kPharmaInstantThemeDuration = Duration.zero;

/// Aplica troca instantânea de cores em estilos de botão locais ([ButtonStyle.styleFrom]).
ButtonStyle pharmaInstantButtonStyle([ButtonStyle? style]) {
  return (style ?? const ButtonStyle()).copyWith(
    animationDuration: kPharmaInstantThemeDuration,
  );
}

/// Superfície com cor/borda do design system, sem animação implícita do [Material].
class PharmaSurface extends StatelessWidget {
  const PharmaSurface({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.clipBehavior = Clip.none,
    this.onTap,
    this.hoverColor,
    this.splashColor,
  });

  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final VoidCallback? onTap;
  final Color? hoverColor;
  final Color? splashColor;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(t.radiusMd);
    final resolvedBorder =
        border ??
        Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.85),
        );

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHighest,
        borderRadius: radius,
        border: resolvedBorder,
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (clipBehavior != Clip.none) {
      content = ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    if (onTap == null) return content;

    return Material(
      type: MaterialType.transparency,
      animationDuration: kPharmaInstantThemeDuration,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: hoverColor,
        splashColor: splashColor,
        child: content,
      ),
    );
  }
}

/// Chip de filtro com cores/bordas estáticas (sem animação do [Material] ao mudar tema).
class PharmaInstantFilterChip extends StatelessWidget {
  const PharmaInstantFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PharmaSurface(
      color: selected
          ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14)
          : scheme.surfaceContainerHighest,
      padding: EdgeInsets.symmetric(
        horizontal: t.density.sm,
        vertical: t.density.xs,
      ),
      onTap: () => onSelected(!selected),
      child: DefaultTextStyle(
        style: textTheme.erpBodyStrong.copyWith(color: t.textPrimary),
        child: label,
      ),
    );
  }
}

/// Campo de texto com borda estática (sem animação do [InputDecorator] ao mudar tema).
class PharmaInstantField extends StatelessWidget {
  const PharmaInstantField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.isDense = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.85),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        style: textTheme.erpBody.copyWith(color: t.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          prefixIcon: prefixIcon,
          isDense: isDense,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: t.density.inputPadding,
          hintStyle: textTheme.erpBodySecondary.copyWith(color: t.textMuted),
          labelStyle: textTheme.erpSelectLabel.copyWith(color: t.textSecondary),
        ),
      ),
    );
  }
}

/// Dropdown enterprise (hover interno + menu abaixo). Mantém API com [DropdownMenuItem].
class PharmaInstantDropdown<T> extends StatelessWidget {
  const PharmaInstantDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.width,
    this.menuMaxHeight,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final double? width;
  final double? menuMaxHeight;

  static String _labelOf(DropdownMenuItem<Object?> item) {
    final child = item.child;
    if (child is Text) return child.data ?? '';
    return item.value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final emptyItems = items.where((item) => item.value == null).toList();
    final valueItems = items.where((item) => item.value != null).toList();
    final emptyLabel =
        emptyItems.isEmpty ? null : _labelOf(emptyItems.first);

    return EnterpriseSelectField<T>(
      label: label,
      width: width,
      menuMaxHeight: menuMaxHeight,
      emptyLabel: emptyLabel,
      value: value,
      enabled: onChanged != null,
      options: [
        for (final item in valueItems)
          EnterpriseSelectOption<T>(
            value: item.value as T,
            label: _labelOf(item),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

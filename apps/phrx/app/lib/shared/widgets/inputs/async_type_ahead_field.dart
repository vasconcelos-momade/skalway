import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import 'enterprise_field_decoration.dart';

/// Campo de texto com sugestões assíncronas (debounce + pesquisa remota).
class AsyncTypeAheadField<T> extends StatelessWidget {
  const AsyncTypeAheadField({
    super.key,
    required this.labelText,
    required this.suggestionsCallback,
    required this.itemLabel,
    required this.onSelected,
    this.hintText,
    this.helperText,
    this.itemSubtitle,
    this.controller,
    this.onChanged,
    this.emptyMessage = 'Nenhum resultado encontrado',
    this.minSearchLength = 2,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.floatingLabel = false,
  });

  final String labelText;
  final String? hintText;
  final String? helperText;
  final Future<List<T>> Function(String query) suggestionsCallback;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final ValueChanged<T> onSelected;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String emptyMessage;
  final int minSearchLength;
  final Duration debounceDuration;

  /// Quando `true`, o label fica dentro do campo (floating) em vez de acima.
  final bool floatingLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final s = t.density;

    final field = TypeAheadField<T>(
      controller: controller,
      debounceDuration: debounceDuration,
      hideOnEmpty: true,
      autoFlipDirection: true,
      constraints: const BoxConstraints(
        maxHeight: DesignMetrics.suggestionsMenuMaxHeight,
      ),
      suggestionsCallback: (pattern) async {
        final query = pattern.trim();
        if (query.length < minSearchLength) {
          return const [];
        }
        return suggestionsCallback(query);
      },
      builder: (context, fieldController, focusNode) {
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          onChanged: onChanged,
          style: textTheme.erpBody.copyWith(color: t.textPrimary),
          textAlignVertical: TextAlignVertical.center,
          decoration: EnterpriseFieldDecoration.of(
            context,
            labelText: floatingLabel ? labelText : null,
            hintText: hintText,
            helperText: helperText,
            floatingLabel: floatingLabel,
            suffixIcon: Icon(
              Icons.search_rounded,
              size: t.iconSm,
              color: t.textMuted,
            ),
          ),
        );
      },
      itemBuilder: (context, item) {
        final subtitle = itemSubtitle?.call(item).trim();
        return ListTile(
          dense: true,
          title: Text(
            itemLabel(item),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle == null || subtitle.isEmpty
              ? null
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        );
      },
      onSelected: onSelected,
      emptyBuilder: (context) {
        return Padding(
          padding: EdgeInsets.all(s.md),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: textTheme.erpBody.copyWith(color: t.textMuted),
          ),
        );
      },
    );

    if (floatingLabel) return field;
    return EnterpriseFieldGroup(labelText: labelText, child: field);
  }
}

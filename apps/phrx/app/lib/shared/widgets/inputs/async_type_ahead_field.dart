import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

/// Campo de texto com sugestões assíncronas (debounce + pesquisa remota).
class AsyncTypeAheadField<T> extends StatelessWidget {
  const AsyncTypeAheadField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.suggestionsCallback,
    required this.itemLabel,
    required this.onSelected,
    this.itemSubtitle,
    this.controller,
    this.minSearchLength = 2,
    this.debounceDuration = const Duration(milliseconds: 350),
  });

  final String labelText;
  final String hintText;
  final Future<List<T>> Function(String query) suggestionsCallback;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final ValueChanged<T> onSelected;
  final TextEditingController? controller;
  final int minSearchLength;
  final Duration debounceDuration;

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<T>(
      controller: controller,
      debounceDuration: debounceDuration,
      hideOnEmpty: true,
      autoFlipDirection: true,
      constraints: const BoxConstraints(maxHeight: 280),
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
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.search),
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
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Nenhum resultado encontrado',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

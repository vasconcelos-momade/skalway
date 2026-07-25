import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../navigation/adaptive_navigator.dart';

/// Dropdown com pesquisa integrada (demo UX — ligar a async repository depois).
class SearchableDropdownField<T> extends StatefulWidget {
  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.display,
    this.onChanged,
    this.hintText = 'Pesquisar…',
  });

  final String label;
  final List<T> items;
  final String Function(T value) display;
  final ValueChanged<T?>? onChanged;
  final String hintText;

  @override
  State<SearchableDropdownField<T>> createState() => _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T> extends State<SearchableDropdownField<T>> {
  T? _selected;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final widths = context.widths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.erpSelectLabel.copyWith(color: t.textSecondary),
        ),
        SizedBox(height: s.sm),
        InkWell(
          onTap: () async {
            _search.clear();
            final picked = await AdaptiveNavigator.openPanel<T>(
              context: context,
              builder: (panelContext) {
                return AlertDialog(
                  backgroundColor: t.card,
                  title: Text(
                    'Seleccionar',
                    style: Theme.of(context).textTheme.erpBodyStrong.copyWith(color: t.textPrimary),
                  ),
                  content: SizedBox(
                    width: widths.formMax * 0.65,
                    height: widths.sideSheetMax * 0.65,
                    child: StatefulBuilder(
                      builder: (context, setLocal) {
                        final panelFiltered = widget.items
                            .where(
                              (e) => widget
                                  .display(e)
                                  .toLowerCase()
                                  .contains(
                                    _search.text.trim().toLowerCase(),
                                  ),
                            )
                            .toList();
                        return Column(
                          children: [
                            TextField(
                              controller: _search,
                              onChanged: (_) => setLocal(() {}),
                              decoration: InputDecoration(
                                hintText: widget.hintText,
                              ),
                            ),
                            SizedBox(height: s.md),
                            Expanded(
                              child: ListView.builder(
                                itemCount: panelFiltered.length,
                                itemBuilder: (c, i) {
                                  final item = panelFiltered[i];
                                  return ListTile(
                                    title: Text(
                                      widget.display(item),
                                      style: Theme.of(context).textTheme.erpSelectValue.copyWith(
                                            color: t.textPrimary,
                                          ),
                                    ),
                                    onTap: () => AdaptiveNavigator.complete(
                                      panelContext,
                                      item,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            );
            if (picked != null) {
              setState(() => _selected = picked);
              widget.onChanged?.call(picked);
            }
          },
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.arrow_drop_down_rounded),
            ),
            child: Text(
              _selected == null ? 'Toque para escolher' : widget.display(_selected as T),
              style: Theme.of(context).textTheme.erpSelectValue.copyWith(
                    color: _selected == null ? t.textMuted : t.textPrimary,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

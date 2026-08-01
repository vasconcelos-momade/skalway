import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../navigation/adaptive_navigator.dart';
import 'enterprise_field_decoration.dart';
import 'enterprise_text_field.dart';

/// Dropdown com pesquisa integrada (demo UX — ligar a async repository depois).
class SearchableDropdownField<T> extends StatefulWidget {
  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.display,
    this.onChanged,
    this.hintText = 'Pesquisar…',
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final String Function(T value) display;
  final ValueChanged<T?>? onChanged;
  final String hintText;
  final bool enabled;

  @override
  State<SearchableDropdownField<T>> createState() =>
      _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T>
    extends State<SearchableDropdownField<T>> {
  T? _selected;
  final _search = TextEditingController();
  bool _hovering = false;

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
    final textTheme = Theme.of(context).textTheme;
    final enabled = widget.enabled && widget.onChanged != null;
    final hasValue = _selected != null;

    final decoration = EnterpriseFieldDecoration.of(
      context,
      hintText: 'Toque para escolher',
      enabled: enabled,
      suffixIcon: Icon(
        Icons.arrow_drop_down_rounded,
        size: t.iconSm,
        color: enabled ? t.textSecondary : t.textMuted,
      ),
    );

    final field = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: enabled ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: !enabled
            ? null
            : () async {
                _search.clear();
                final picked = await AdaptiveNavigator.openPanel<T>(
                  context: context,
                  builder: (panelContext) {
                    return AlertDialog(
                      backgroundColor: t.card,
                      title: Text(
                        'Seleccionar',
                        style: textTheme.erpBodyStrong
                            .copyWith(color: t.textPrimary),
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
                                EnterpriseTextField(
                                  controller: _search,
                                  hintText: widget.hintText,
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: t.iconSm,
                                    color: t.textMuted,
                                  ),
                                  onChanged: (_) => setLocal(() {}),
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
                                          style: textTheme.erpSelectValue
                                              .copyWith(color: t.textPrimary),
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
        child: InputDecorator(
          isHovering: _hovering,
          isEmpty: !hasValue,
          decoration: decoration,
          child: Text(
            hasValue
                ? widget.display(_selected as T)
                : 'Toque para escolher',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.erpBody.copyWith(
              color: hasValue
                  ? (enabled ? t.textPrimary : t.textMuted)
                  : t.textMuted,
            ),
          ),
        ),
      ),
    );

    return EnterpriseFieldGroup(labelText: widget.label, child: field);
  }
}

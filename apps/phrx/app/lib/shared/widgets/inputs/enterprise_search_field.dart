import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../responsive/pharma_screen_layout.dart';

/// Campo de pesquisa enterprise unificado (tabelas/listagens/toolbars/dialogs).
///
/// Largura (design system):
/// - Desktop: [DesignMetrics.searchFieldMaxWidthDesktop]
/// - Tablet: [DesignMetrics.searchFieldMaxWidthTablet]
/// - Mobile: 100% da largura disponível
class EnterpriseSearchField extends StatefulWidget {
  const EnterpriseSearchField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.focusNode,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  State<EnterpriseSearchField> createState() => _EnterpriseSearchFieldState();
}

class _EnterpriseSearchFieldState extends State<EnterpriseSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnterpriseSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  double? _maxWidthFor(BuildContext context) {
    if (PharmaScreenLayout.isMobile(context)) return null;
    if (PharmaScreenLayout.isDesktop(context)) {
      return DesignMetrics.searchFieldMaxWidthDesktop;
    }
    return DesignMetrics.searchFieldMaxWidthTablet;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final inputTheme = theme.inputDecorationTheme;

    final outline = BorderSide(
      color: scheme.outline.withValues(alpha: isDark ? 0.6 : 0.85),
    );

    final field = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
      decoration: InputDecoration(
        labelText: widget.hintText,
        isDense: true,
        filled: inputTheme.filled,
        fillColor: inputTheme.fillColor,
        contentPadding: inputTheme.contentPadding ?? t.density.inputPadding,
        constraints: inputTheme.constraints ??
            BoxConstraints(minHeight: t.minTouchTarget),
        labelStyle: inputTheme.labelStyle ??
            theme.textTheme.erpSelectLabel.copyWith(color: t.textSecondary),
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
        prefixIcon: Icon(
          Icons.search_rounded,
          color: t.textMuted,
          size: t.iconSm,
        ),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Limpar',
                icon: Icon(
                  Icons.clear_rounded,
                  color: t.textMuted,
                  size: t.iconSm,
                ),
                onPressed: _clear,
              )
            : null,
      ),
    );

    final maxWidth = _maxWidthFor(context);
    if (maxWidth == null) return field;

    // Obrigatório em Row/toolbar: TextField não aceita largura infinita.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: field,
    );
  }
}

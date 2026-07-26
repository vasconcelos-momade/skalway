import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../responsive/pharma_screen_layout.dart';
import '../../../core/theme/design_metrics.dart';
import 'enterprise_field_decoration.dart';

/// Campo de pesquisa enterprise unificado (tabelas/listagens/toolbars/dialogs).
///
/// Largura (design system):
/// - Desktop: [DesignMetrics.searchFieldMaxWidthDesktop]
/// - Tablet: [DesignMetrics.searchFieldMaxWidthTablet]
/// - Mobile: 100% da largura disponível
///
/// Altura: [PharmaTokens.controlHeight] (igual a botões / select / date).
class EnterpriseSearchField extends StatefulWidget {
  const EnterpriseSearchField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
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
    widget.onSubmitted?.call('');
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

    // Toolbar: altura exacta = botões (sem label flutuante que ultrapassa a caixa).
    final field = SizedBox(
      height: t.controlHeight,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
        textAlignVertical: TextAlignVertical.center,
        decoration: EnterpriseFieldDecoration.of(
          context,
          hintText: widget.hintText,
          floatingLabel: false,
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
      ),
    );

    final maxWidth = _maxWidthFor(context);
    if (maxWidth == null) return field;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: field,
    );
  }
}

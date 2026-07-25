import 'package:flutter/material.dart';

import '../inputs/enterprise_search_field.dart';

/// Campo de pesquisa padronizado para módulos enterprise (mobile e desktop).
class EnterpriseModuleSearchBar extends StatefulWidget {
  const EnterpriseModuleSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.enabled = true,
    this.onChanged,
    this.maxWidth,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final double? maxWidth;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<EnterpriseModuleSearchBar> createState() => _EnterpriseModuleSearchBarState();
}

class _EnterpriseModuleSearchBarState extends State<EnterpriseModuleSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnterpriseModuleSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Mantido por compatibilidade: todo o sistema deve usar EnterpriseSearchField.
    // `onSubmitted` é mapeado para `onChanged` (mesmo fluxo de filtros/busca nas telas).
    final onChanged = widget.onChanged ?? widget.onSubmitted;
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: EnterpriseSearchField(
        hintText: widget.hintText,
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: onChanged,
      ),
    );
  }
}

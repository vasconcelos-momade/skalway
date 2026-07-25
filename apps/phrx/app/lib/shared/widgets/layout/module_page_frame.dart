import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Moldura comum para páginas de módulo (título opcional + conteúdo scrollável).
class ModulePageFrame extends StatelessWidget {
  const ModulePageFrame({
    super.key,
    this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.scrollable = true,
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;
  final bool scrollable;

  bool get _showsHeader =>
      (title != null && title!.trim().isNotEmpty) || actions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showsHeader)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.trim().isNotEmpty)
                Expanded(
                  child: Text(
                    title!,
                    style: context.erpPageTitle.copyWith(color: t.textPrimary),
                  ),
                )
              else
                const Spacer(),
              if (actions.isNotEmpty) ...[
                if (title != null && title!.trim().isNotEmpty)
                  SizedBox(width: s.md),
                Wrap(spacing: s.sm, runSpacing: s.sm, children: actions),
              ],
            ],
          ),
        if (_showsHeader) SizedBox(height: s.lg),
        Expanded(
          child: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ],
    );
  }
}

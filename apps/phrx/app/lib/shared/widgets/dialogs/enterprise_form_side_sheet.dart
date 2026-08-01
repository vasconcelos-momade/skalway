import 'package:flutter/material.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import 'enterprise_overlay_chrome.dart';

/// Shell de formulário em side sheet (padrão categorias / enterprise).
///
/// - Header fixo com fechar
/// - Body top-aligned (sem área vazia forçada entre campos e rodapé)
/// - Footer fixo com [borderSubtle], botões à direita
/// - Superfície elevada (Surface 2) + borda 1px + sombra leve
class EnterpriseFormSideSheet extends StatelessWidget {
  const EnterpriseFormSideSheet({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.subtitle,
    this.onClose,
    this.showHeader = true,
    this.scrollable = true,
  });

  final Widget title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final bool showHeader;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    final paddedBody = Padding(
      padding: EdgeInsets.fromLTRB(s.lg, s.md, s.lg, s.md),
      child: body,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          EnterpriseOverlayHeader(
            title: title,
            subtitle: subtitle,
            showClose: onClose != null,
            onClose: onClose,
          ),
          Divider(height: BorderTokens.width, color: t.borderSubtle),
        ],
        // Campos no topo; footer fixo — sem Spacer entre conteúdo e rodapé.
        Expanded(
          child: scrollable
              ? SingleChildScrollView(child: paddedBody)
              : Align(
                  alignment: Alignment.topCenter,
                  child: paddedBody,
                ),
        ),
        if (actions.isNotEmpty)
          EnterpriseOverlayFooter(
            actions: actions,
            expandOnNarrow: false,
          ),
      ],
    );
  }
}

/// Switch de formulário — label e controlo alinhados verticalmente.
class EnterpriseFormSwitch extends StatelessWidget {
  const EnterpriseFormSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.erpFieldLabel.copyWith(
                    color: t.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: s.xxs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.erpCaption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: s.md),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Decoração de superfície do painel lateral (Surface 2 + borda + sombra).
BoxDecoration enterpriseSideSheetDecoration(BuildContext context) {
  final t = context.pharmaTokens;
  return BoxDecoration(
    color: t.surface2,
    border: Border(
      left: BorderSide(
        color: t.borderSubtle,
        width: BorderTokens.width,
      ),
    ),
    boxShadow: AppShadows.panelEdge(context, fromLeft: false),
  );
}

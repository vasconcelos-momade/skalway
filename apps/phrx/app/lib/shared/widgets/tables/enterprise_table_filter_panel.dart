import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../responsive/pharma_screen_layout.dart';
import '../dialogs/enterprise_overlay_tokens.dart';
import '../dialogs/enterprise_side_sheet.dart';
import '../menus/enterprise_dropdown_menu.dart';
import '../../../core/theme/pharma_border_tokens.dart';

/// Painel de filtros avançados da tabela enterprise.
///
/// Responsável por:
/// - Renderizar filtros disponíveis
/// - Aplicar / limpar filtros
/// - Controlar o chrome do painel (título + acções)
///
/// A [EnterpriseTableToolbar] apenas dispara a abertura —
/// a lógica de filtros permanece neste painel / no caller.
class EnterpriseTableFilterPanel extends StatelessWidget {
  const EnterpriseTableFilterPanel({
    super.key,
    required this.filters,
    this.title = 'Filtros',
    this.onClear,
    this.onApply,
    this.clearLabel = 'Limpar',
    this.applyLabel = 'Aplicar',
    this.showActions = true,
    this.dense = false,
  });

  /// Widgets de filtro (selects, chips, date pickers, etc.).
  final List<Widget> filters;

  final String title;
  final VoidCallback? onClear;
  final VoidCallback? onApply;
  final String clearLabel;
  final String applyLabel;
  final bool showActions;

  /// Layout mais compacto (dropdown desktop).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final colors = context.colors;
    final radius = context.radius;
    final gap = dense ? s.sm : s.md;

    final panelRadius = BorderRadius.circular(radius.md);

    return Material(
      color: Colors.transparent,
      elevation: dense ? context.elevationTokens.level2 : 0,
      shadowColor: colors.overlay,
      borderRadius: panelRadius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: dense
            ? EnterpriseDropdownMenu.surfaceDecoration(context)
            : BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: panelRadius,
                border: Border.all(
                  color: t.border,
                  width: context.borders.borderThin,
                ),
              ),
        padding: EdgeInsets.all(dense ? s.md : s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: gap),
            Divider(height: 1, color: t.border),
            SizedBox(height: gap),
            for (var i = 0; i < filters.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              filters[i],
            ],
            if (showActions && (onClear != null || onApply != null)) ...[
              SizedBox(height: dense ? s.md : s.lg),
              Row(
                children: [
                  if (onClear != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClear,
                        child: Text(clearLabel),
                      ),
                    ),
                  if (onClear != null && onApply != null) SizedBox(width: s.md),
                  if (onApply != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: onApply,
                        child: Text(applyLabel),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Apresenta o painel: dropdown em desktop, side sheet em tablet/mobile.
  ///
  /// Em desktop, passe [anchorContext] (ex.: o botão Filtros) para posicionar
  /// o dropdown. Sem âncora, usa side sheet também no desktop.
  static Future<void> present({
    required BuildContext context,
    required List<Widget> filters,
    String title = 'Filtros',
    VoidCallback? onClear,
    VoidCallback? onApply,
    BuildContext? anchorContext,
  }) {
    final useDropdown =
        PharmaScreenLayout.isDesktop(context) && anchorContext != null;

    if (useDropdown) {
      final box = anchorContext.findRenderObject() as RenderBox?;
      final overlayBox =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (box != null && overlayBox != null && box.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
        return _showDropdown(
          context: context,
          filters: filters,
          title: title,
          onClear: onClear,
          onApply: onApply,
          anchor: topLeft,
          anchorSize: box.size,
        );
      }
    }

    return _showSideSheet(
      context: context,
      filters: filters,
      title: title,
      onClear: onClear,
      onApply: onApply,
    );
  }

  static Future<void> _showSideSheet({
    required BuildContext context,
    required List<Widget> filters,
    required String title,
    VoidCallback? onClear,
    VoidCallback? onApply,
  }) {
    return EnterpriseSideSheet.showChrome<void>(
      context: context,
      size: EnterpriseOverlaySize.small,
      title: Text(title),
      icon: Icons.tune_rounded,
      body: EnterpriseTableFilterPanel(
        filters: filters,
        title: title,
        showActions: false,
      ),
      actions: [
        if (onClear != null)
          Builder(
            builder: (sheetContext) => OutlinedButton(
              onPressed: () {
                onClear();
                closeEnterpriseSideSheet(sheetContext);
              },
              child: const Text('Limpar'),
            ),
          ),
        if (onApply != null)
          Builder(
            builder: (sheetContext) => FilledButton(
              onPressed: () {
                onApply();
                closeEnterpriseSideSheet(sheetContext);
              },
              child: const Text('Aplicar'),
            ),
          ),
      ],
    );
  }

  static Future<void> _showDropdown({
    required BuildContext context,
    required List<Widget> filters,
    required String title,
    VoidCallback? onClear,
    VoidCallback? onApply,
    required Offset anchor,
    required Size anchorSize,
  }) {
    final overlay = Overlay.of(context);
    final completer = Completer<void>();
    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) entry.remove();
      if (!completer.isCompleted) completer.complete();
    }

    entry = OverlayEntry(
      builder: (overlayContext) {
        final s = overlayContext.spacing;
        final media = MediaQuery.sizeOf(overlayContext);
        final panelWidth = overlayContext.widths.dropdownMenu * 1.6;
        final left = (anchor.dx + anchorSize.width - panelWidth)
            .clamp(s.md, media.width - panelWidth - s.md);
        final top = anchor.dy + anchorSize.height + s.xs;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: panelWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: media.height - top - s.lg,
                ),
                child: SingleChildScrollView(
                  child: EnterpriseTableFilterPanel(
                    dense: true,
                    title: title,
                    filters: filters,
                    onClear: onClear == null
                        ? null
                        : () {
                            onClear();
                            dismiss();
                          },
                    onApply: onApply == null
                        ? null
                        : () {
                            onApply();
                            dismiss();
                          },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(entry);
    return completer.future;
  }
}

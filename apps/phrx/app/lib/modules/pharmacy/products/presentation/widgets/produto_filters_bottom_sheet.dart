import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../categories/domain/entities/category.dart';
import 'produto_filters_content.dart';

class ProdutoFiltersBottomSheet extends StatefulWidget {
  const ProdutoFiltersBottomSheet({
    super.key,
    required this.initialAtivo,
    required this.initialCategoriaId,
    required this.categories,
    required this.onApply,
  });

  final bool? initialAtivo;
  final String? initialCategoriaId;
  final List<Category> categories;
  final void Function(bool? ativo, String? categoriaId) onApply;

  @override
  State<ProdutoFiltersBottomSheet> createState() => _ProdutoFiltersBottomSheetState();
}

class _ProdutoFiltersBottomSheetState extends State<ProdutoFiltersBottomSheet> {
  late bool? _ativo;
  late String? _categoriaId;

  @override
  void initState() {
    super.initState();
    _ativo = widget.initialAtivo;
    _categoriaId = widget.initialCategoriaId;
  }

  void _clearFilters() {
    setState(() {
      _ativo = null;
      _categoriaId = null;
    });
    widget.onApply(null, null);
    Navigator.of(context).pop();
  }

  void _applyFilters() {
    widget.onApply(_ativo, _categoriaId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    // Considera a altura do teclado caso existam inputs
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusXl)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: s.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(t.radiusMd / 2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtros',
                      style: theme.textTheme.erpCardTitle.copyWith(
                        color: t.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: t.textMuted, size: t.iconSm),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: t.border.withValues(alpha: 0.45)),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(s.md, s.md, s.md, s.sm),
                  child: ProdutoFiltersContent(
                    ativo: _ativo,
                    categoriaId: _categoriaId,
                    categories: widget.categories,
                    onAtivoChanged: (value) => setState(() => _ativo = value),
                    onCategoriaChanged: (value) =>
                        setState(() => _categoriaId = value),
                    onClear: _clearFilters,
                    onApply: (_, _) => _applyFilters(),
                    showActions: false,
                  ),
                ),
              ),
              Divider(height: 1, color: t.border.withValues(alpha: 0.45)),
              Padding(
                padding: EdgeInsets.fromLTRB(s.md, s.sm, s.md, s.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        child: const Text('Limpar'),
                      ),
                    ),
                    SizedBox(width: s.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _applyFilters,
                        child: const Text('Aplicar filtros'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

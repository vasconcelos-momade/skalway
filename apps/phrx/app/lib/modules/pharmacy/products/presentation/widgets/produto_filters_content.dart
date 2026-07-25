import 'package:flutter/material.dart';

import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../categories/domain/entities/category.dart';

/// Painel de filtros reutilizado no dropdown (desktop) e bottom sheet (mobile).
class ProdutoFiltersContent extends StatelessWidget {
  const ProdutoFiltersContent({
    super.key,
    required this.ativo,
    required this.categoriaId,
    required this.categories,
    required this.onAtivoChanged,
    required this.onCategoriaChanged,
    required this.onClear,
    required this.onApply,
    this.compact = false,
    this.showActions = true,
  });

  final bool? ativo;
  final String? categoriaId;
  final List<Category> categories;
  final ValueChanged<bool?> onAtivoChanged;
  final ValueChanged<String?> onCategoriaChanged;
  final VoidCallback onClear;
  final void Function(bool? ativo, String? categoriaId) onApply;
  final bool compact;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnterpriseSelectField<bool>(
          key: ValueKey('produto-filter-status-$ativo'),
          label: 'Status',
          emptyLabel: 'Todos',
          value: ativo,
          options: const [
            EnterpriseSelectOption<bool>(value: true, label: 'Activos'),
            EnterpriseSelectOption<bool>(value: false, label: 'Inactivos'),
          ],
          onChanged: onAtivoChanged,
        ),
        SizedBox(height: s.md),
        EnterpriseSelectField<String>(
          key: ValueKey('produto-filter-categoria-$categoriaId'),
          label: 'Categoria',
          emptyLabel: 'Todas',
          value: categoriaId,
          menuMaxHeight: 400,
          options: [
            for (final cat in categories)
              EnterpriseSelectOption<String>(value: cat.id, label: cat.nome),
          ],
          onChanged: onCategoriaChanged,
        ),
        if (showActions) ...[
          SizedBox(height: s.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Limpar'),
                ),
              ),
              SizedBox(width: s.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => onApply(ativo, categoriaId),
                  child: Text(compact ? 'Aplicar' : 'Aplicar filtros'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

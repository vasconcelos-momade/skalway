import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../categories/domain/entities/category.dart';
import '../providers/estoque_provider.dart';

class EstoqueFiltersBottomSheet extends StatefulWidget {
  const EstoqueFiltersBottomSheet({
    super.key,
    required this.initialState,
    required this.categories,
    required this.fornecedores,
    required this.onApply,
  });

  final EstoqueListState initialState;
  final List<Category> categories;
  final List<({String id, String nome})> fornecedores;
  final void Function({
    String? categoriaId,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? semStock,
    bool? aExpirar,
    bool? expirado,
  }) onApply;

  @override
  State<EstoqueFiltersBottomSheet> createState() =>
      _EstoqueFiltersBottomSheetState();
}

class _EstoqueFiltersBottomSheetState extends State<EstoqueFiltersBottomSheet> {
  late String? _categoriaId = widget.initialState.categoriaId;
  late String? _fornecedorId = widget.initialState.fornecedorId;
  late String? _estadoSanitario = widget.initialState.estadoSanitario;
  late String? _disponibilidade = widget.initialState.disponibilidade;
  late bool _semStock = widget.initialState.semStock == true;
  late bool _aExpirar = widget.initialState.aExpirar == true;
  late bool _expirado = widget.initialState.expirado == true;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        s.md,
        s.md,
        s.md,
        s.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.erpSectionTitle),
            SizedBox(height: s.md),
            EnterpriseSelectField<String>(
              key: ValueKey('sheet-cat-$_categoriaId'),
              label: 'Categoria',
              emptyLabel: 'Todas',
              value: _categoriaId,
              options: [
                for (final c in widget.categories)
                  EnterpriseSelectOption<String>(value: c.id, label: c.nome),
              ],
              onChanged: (value) => setState(() => _categoriaId = value),
            ),
            SizedBox(height: s.md),
            EnterpriseSelectField<String>(
              key: ValueKey('sheet-forn-$_fornecedorId'),
              label: 'Fornecedor',
              emptyLabel: 'Todos',
              value: _fornecedorId,
              options: [
                for (final f in widget.fornecedores)
                  EnterpriseSelectOption<String>(value: f.id, label: f.nome),
              ],
              onChanged: (value) => setState(() => _fornecedorId = value),
            ),
            SizedBox(height: s.md),
            EnterpriseSelectField<String>(
              key: ValueKey('sheet-estado-$_estadoSanitario'),
              label: 'Estado sanitário',
              emptyLabel: 'Todos',
              value: _estadoSanitario,
              options: const [
                EnterpriseSelectOption<String>(value: 'VALIDO', label: 'Válido'),
                EnterpriseSelectOption<String>(
                  value: 'EXPIRADO',
                  label: 'Expirado',
                ),
                EnterpriseSelectOption<String>(value: 'RECALL', label: 'Recall'),
                EnterpriseSelectOption<String>(
                  value: 'QUARENTENA',
                  label: 'Quarentena',
                ),
              ],
              onChanged: (value) => setState(() => _estadoSanitario = value),
            ),
            SizedBox(height: s.md),
            EnterpriseSelectField<String>(
              key: ValueKey('sheet-disp-$_disponibilidade'),
              label: 'Disponibilidade',
              emptyLabel: 'Todas',
              value: _disponibilidade,
              options: const [
                EnterpriseSelectOption<String>(
                  value: 'DISPONIVEL',
                  label: 'Disponível',
                ),
                EnterpriseSelectOption<String>(
                  value: 'BLOQUEADO',
                  label: 'Bloqueado',
                ),
                EnterpriseSelectOption<String>(
                  value: 'INDISPONIVEL',
                  label: 'Indisponível',
                ),
              ],
              onChanged: (value) => setState(() => _disponibilidade = value),
            ),
            SizedBox(height: s.sm),
            FilterChip(
              label: const Text('Produtos sem stock'),
              selected: _semStock,
              onSelected: (value) => setState(() => _semStock = value),
            ),
            FilterChip(
              label: const Text('Lotes a expirar (60 dias)'),
              selected: _aExpirar,
              onSelected: (value) => setState(() => _aExpirar = value),
            ),
            FilterChip(
              label: const Text('Apenas lotes expirados'),
              selected: _expirado,
              onSelected: (value) => setState(() => _expirado = value),
            ),
            SizedBox(height: s.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _categoriaId = null;
                        _fornecedorId = null;
                        _estadoSanitario = null;
                        _disponibilidade = null;
                        _semStock = false;
                        _aExpirar = false;
                        _expirado = false;
                      });
                    },
                    child: const Text('Limpar'),
                  ),
                ),
                SizedBox(width: s.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(
                        categoriaId: _categoriaId,
                        fornecedorId: _fornecedorId,
                        estadoSanitario: _estadoSanitario,
                        disponibilidade: _disponibilidade,
                        semStock: _semStock ? true : null,
                        aExpirar: _aExpirar ? true : null,
                        expirado: _expirado ? true : null,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

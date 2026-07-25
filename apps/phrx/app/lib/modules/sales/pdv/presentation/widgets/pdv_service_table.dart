import 'package:flutter/material.dart';

import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/table_typography.dart';
import '../../domain/entities/pdv_service.dart';
import 'pdv_catalog_utils.dart';

class PdvServiceTable extends StatelessWidget {
  const PdvServiceTable({
    super.key,
    required this.items,
    required this.query,
    required this.canAdd,
    required this.onAdd,
  });

  final List<PdvService> items;
  final String query;
  final bool canAdd;
  final void Function(PdvService service) onAdd;

  static const _columns = ['SERVIÇO', 'TIPO', 'PREÇO', 'AÇÕES'];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ModuleEmptyState(
        title: query.isEmpty
            ? 'Nenhum serviço disponível.'
            : 'Nenhum serviço encontrado.',
        subtitle: query.isEmpty ? null : 'Tente outro nome de serviço.',
      );
    }

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      columns: [
        for (final label in _columns)
          DataColumn(label: TableTypography.headerLabel(context, label)),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final service = items[index];
        return DataRow(
          onSelectChanged: canAdd ? (_) => onAdd(service) : null,
          cells: [
            DataCell(
              TableTypography.cellText(
                context,
                service.nome,
                style: TableTypography.primary(context),
              ),
            ),
            DataCell(TableTypography.cellText(context, service.tipoServicoClinico ?? '—')),
            DataCell(TableTypography.cellText(context, pdvFormatMoney(service.preco))),
            DataCell(
              FilledButton.tonalIcon(
                onPressed: canAdd ? () => onAdd(service) : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ),
          ],
        );
      },
    );
  }
}

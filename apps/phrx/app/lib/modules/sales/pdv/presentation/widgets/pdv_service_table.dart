import 'package:flutter/material.dart';

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
    this.pagination,
  });

  final List<PdvService> items;
  final String query;
  final bool canAdd;
  final void Function(PdvService service) onAdd;
  final Widget? pagination;

  static const _columns = ['SERVIÇO', 'TIPO', 'PREÇO', 'AÇÕES'];

  EnterpriseTableStatus get _status {
    if (items.isEmpty) return EnterpriseTableStatus.empty;
    return EnterpriseTableStatus.data;
  }

  @override
  Widget build(BuildContext context) {
    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      status: _status,
      emptyTitle: query.isEmpty
          ? 'Nenhum registo encontrado'
          : 'Nenhum serviço encontrado.',
      emptyMessage: 'Nenhum registo encontrado',
      emptySubtitle: query.isEmpty ? null : 'Tente outro nome de serviço.',
      pagination: pagination,
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
            DataCell(
              TableTypography.cellText(
                context,
                service.tipoServicoClinico ?? '—',
              ),
            ),
            DataCell(
              TableTypography.cellText(context, pdvFormatMoney(service.preco)),
            ),
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

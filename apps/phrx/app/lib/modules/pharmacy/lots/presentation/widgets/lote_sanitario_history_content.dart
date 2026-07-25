import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';

/// Conteúdo do histórico sanitário do lote — desacoplado do container.
class LoteSanitarioHistoryContent extends ConsumerWidget {
  const LoteSanitarioHistoryContent({
    super.key,
    required this.loteId,
    this.numeroLote,
    this.showHeader = true,
    this.onClose,
  });

  final String loteId;
  final String? numeroLote;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref
          .read(inventoryRemoteDataSourceProvider)
          .getLoteSanitarioHistory(loteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final data = snapshot.data ?? const <String, dynamic>{};
        final lote = data['lote'] as Map<String, dynamic>? ?? const {};
        final title = numeroLote ?? lote['numeroLote']?.toString() ?? loteId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Histórico sanitário • $title',
                        style: Theme.of(context).textTheme.erpCardTitle,
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            Expanded(child: _HistoryBody(data: data)),
          ],
        );
      },
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final movimentos = data['movimentos'] as List<dynamic>? ?? const [];
    final incineracoes = data['incineracoes'] as List<dynamic>? ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Movimentos sanitários',
          style: Theme.of(context).textTheme.erpBodyStrong,
        ),
        const SizedBox(height: 8),
        if (movimentos.isEmpty)
          const Text('Sem movimentos sanitários registados.')
        else
          ...movimentos.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${item['tipo']} • ${item['quantidade']}'),
              subtitle: Text(
                [
                  item['motivo']?.toString(),
                  item['responsavel']?['nome']?.toString(),
                  item['createdAt']?.toString(),
                ].whereType<String>().where((v) => v.isNotEmpty).join(' • '),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Incinerações', style: Theme.of(context).textTheme.erpBodyStrong),
        const SizedBox(height: 8),
        if (incineracoes.isEmpty)
          const Text('Sem incinerações associadas.')
        else
          ...incineracoes.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Auto ${item['numeroAuto'] ?? item['id']} • ${item['quantidade'] ?? 0}',
              ),
              subtitle: Text(item['dataIncineracao']?.toString() ?? '—'),
            ),
          ),
      ],
    );
  }
}

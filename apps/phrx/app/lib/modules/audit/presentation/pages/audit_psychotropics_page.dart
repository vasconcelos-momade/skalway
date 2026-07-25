import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../pharmacy/regulatory/data/datasources/regulatory_remote_datasource.dart';

class AuditPsychotropicsPage extends ConsumerStatefulWidget {
  const AuditPsychotropicsPage({super.key});

  @override
  ConsumerState<AuditPsychotropicsPage> createState() =>
      _AuditPsychotropicsPageState();
}

class _AuditPsychotropicsPageState
    extends ConsumerState<AuditPsychotropicsPage> {
  late final TextEditingController _searchController;
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _items = const [];
  int _page = 1;
  int _pageSize = 20;
  bool _hasMore = false;
  String _search = '';

  RegulatoryRemoteDataSource get _ds =>
      ref.read(regulatoryRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _ds.livroPsicotropicosDashboard(
          search: _search.isEmpty ? null : _search,
        ),
        _ds.listLivroPsicotropicos(
          search: _search.isEmpty ? null : _search,
          page: _page,
          pageSize: _pageSize,
        ),
      ]);
      final page = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _items = page.items.cast<Map<String, dynamic>>();
        _page = page.page as int;
        _pageSize = page.pageSize as int;
        _hasMore = page.hasMore as bool;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final dash =
        _dashboard?['kpis'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    return EnterpriseModuleHub(
      title: 'Auditoria de psicotrópicos',
      subtitle: 'Livro B, receitas, retenção e cruzamento regulatório.',
      tag: 'Auditoria',
      actions: [
        OutlinedButton.icon(
          onPressed: _loading ? null : () => _load(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) {
                _search = value.trim();
                _page = 1;
                _load();
              },
              decoration: const InputDecoration(
                hintText: 'Produto, documento...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      kpis: [
        EnterpriseStatCard(
          title: 'Movimentos',
          value: '${dash['totalMovimentos'] ?? _items.length}',
          icon: Icons.verified_user_outlined,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Entradas',
          value: '${dash['entradas'] ?? 0}',
          icon: Icons.login,
          accent: StatCardAccent.positive,
        ),
        EnterpriseStatCard(
          title: 'Saídas',
          value: '${dash['saidas'] ?? 0}',
          icon: Icons.logout,
          accent: StatCardAccent.warning,
        ),
      ],
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const ModuleLoadingState();
    if (_error != null) {
      return ModuleErrorState(
        title: 'Falha ao carregar auditoria',
        message: _error!,
        onRetry: () => _load(),
        icon: Icons.verified_user_outlined,
      );
    }
    if (_items.isEmpty) {
      return const ModuleEmptyState(
        title: 'Sem movimentos auditáveis',
        subtitle:
            'Não existem registos de psicotrópicos para os filtros actuais.',
      );
    }

    final t = context.pharmaTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: EnterpriseDataTable(
            columns: [
              for (final label in [
                'Data',
                'Documento',
                'Produto',
                'Movimento',
                'Qtd',
              ])
                DataColumn(
                  label: Text(
                    label.toUpperCase(),
                    style: Theme.of(
                      context,
                    ).textTheme.erpOverline.copyWith(color: t.textMuted),
                  ),
                ),
            ],
            rowCount: _items.length,
            rowBuilder: (context, index) {
              final item = _items[index];
              final createdAt =
                  DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
                  DateTime.now();
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      _dateTime.format(createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ),
                  DataCell(
                    Text(
                      item['numeroDocumento']?.toString() ?? '—',
                      style: Theme.of(
                        context,
                      ).textTheme.erpLabel.copyWith(color: t.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      item['produto']?['nome']?.toString() ?? '—',
                      style: Theme.of(context).textTheme.erpBodySecondary
                          .copyWith(color: t.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      item['tipoMovimento']?.toString() ?? '—',
                      style: Theme.of(
                        context,
                      ).textTheme.erpBody.copyWith(color: t.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${item['quantidade'] ?? 0}',
                      style: Theme.of(
                        context,
                      ).textTheme.erpTabLabel.copyWith(color: t.brandGreen),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        MovimentacoesPagination(
          page: _page,
          pageSize: _pageSize,
          hasMore: _hasMore,
          isBusy: _loading,
          onPrev: _page > 1
              ? () {
                  _page -= 1;
                  _load();
                }
              : null,
          onNext: _hasMore
              ? () {
                  _page += 1;
                  _load();
                }
              : null,
          onPageSizeChanged: (size) {
            _pageSize = size;
            _page = 1;
            _load();
          },
        ),
      ],
    );
  }
}

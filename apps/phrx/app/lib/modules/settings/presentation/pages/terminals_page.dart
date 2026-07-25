import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/terminal.dart';
import '../providers/terminal_list_provider.dart';
import '../widgets/terminal_form_dialog.dart';

class TerminalsPage extends ConsumerStatefulWidget {
  const TerminalsPage({super.key});

  @override
  ConsumerState<TerminalsPage> createState() => _TerminalsPageState();
}

class _TerminalsPageState extends ConsumerState<TerminalsPage> {
  final _searchController = TextEditingController();
  List<TerminalDetalhe> _accumulatedItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final state = ref.watch(terminalListProvider);
    final controller = ref.read(terminalListProvider.notifier);

    if (_searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    ref.listen(terminalListProvider, (prev, next) {
      if (prev?.page != next.page || prev?.query != next.query) {
        if (next.page == 1) {
          _accumulatedItems = List.of(next.items);
        } else {
          _accumulatedItems.addAll(
            next.items.where((e) => !_accumulatedItems.any((a) => a.id == e.id)),
          );
        }
      } else if (prev?.items != next.items && next.page == 1) {
        _accumulatedItems = List.of(next.items);
      }
    });

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return Scaffold(
          backgroundColor: t.bgPrimary,
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  onPressed: state.isLoading ? null : () => _openCreate(context),
                  child: const Icon(Icons.add),
                )
              : null,
          body: EnterpriseModuleHub(
            title: 'Terminais',
            subtitle: 'Registo de dispositivos POS e caixas associadas.',
            tag: AppNavSections.system,
            actions: isMobile
                ? null
                : [
                    OutlinedButton.icon(
                      onPressed: state.isLoading ? null : controller.refreshCurrentPage,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Atualizar'),
                    ),
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : () => _openCreate(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Novo terminal'),
                    ),
                  ],
            child: Column(
              children: [
                if (state.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: s.sm),
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                            color: t.posDanger,
                          ),
                    ),
                  ),
                Expanded(
                  child: state.isLoading && !state.isInitialized
                      ? const ModuleLoadingState()
                      : isMobile
                          ? EnterpriseMobileScrollList(
                              stickyHeader: EnterpriseMobileToolbar(
                                searchController: _searchController,
                                searchHint: 'Código, nome ou localização...',
                                enabled: !state.isLoading,
                                isLoading: state.isLoading,
                                hasFilters: state.query.isNotEmpty,
                                showFiltersButton: false,
                                onSearchSubmitted: controller.onSearchChanged,
                                onOpenFilters: () {},
                                onClearFilters: () async {
                                  controller.onSearchChanged('');
                                },
                                onRefresh: controller.refreshCurrentPage,
                              ),
                              itemCount: _accumulatedItems.length,
                              itemBuilder: (context, index) {
                                final item = _accumulatedItems[index];
                                return EnterpriseListCard(
                                  leading: Icons.point_of_sale_outlined,
                                  title: item.nome,
                                  subtitle: item.codigo,
                                  chip: EnterpriseStatusChip(
                                    label: item.ativo ? 'Activo' : 'Inactivo',
                                    color: item.ativo ? t.brandGreen : t.textMuted,
                                  ),
                                  metadata: [
                                    EnterpriseListCardMeta(
                                      label: 'Localização: ${item.localizacao ?? '—'}',
                                    ),
                                    if (item.caixaId != null)
                                      EnterpriseListCardMeta(
                                        label: 'Caixa: ${item.caixaId}',
                                      ),
                                  ],
                                  onTap: () => _openEdit(context, item),
                                );
                              },
                              hasMore: state.hasMore,
                              isLoading: state.isLoading,
                              onLoadMore: () => controller.goToPage(state.page + 1),
                              emptyMessage: 'Nenhum terminal encontrado',
                              totalCount: state.totalCount,
                            )
                          : EnterpriseDataTable(
                              showCheckboxColumn: false,
                              columns: const [
                                DataColumn(label: Text('CÓDIGO')),
                                DataColumn(label: Text('NOME')),
                                DataColumn(label: Text('LOCALIZAÇÃO')),
                                DataColumn(label: Text('CAIXA')),
                                DataColumn(label: Text('ESTADO')),
                                DataColumn(label: Text('AÇÕES')),
                              ],
                              rowCount: state.items.length,
                              rowBuilder: (context, index) {
                                final item = state.items[index];
                                return DataRow(
                                  cells: [
                                    DataCell(Text(item.codigo)),
                                    DataCell(Text(item.nome)),
                                    DataCell(Text(item.localizacao ?? '—')),
                                    DataCell(Text(item.caixaId ?? '—')),
                                    DataCell(Text(item.ativo ? 'Activo' : 'Inactivo')),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'editar') {
                                            _openEdit(context, item);
                                          } else if (action == 'excluir') {
                                            _confirmDelete(context, item);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'editar', child: Text('Editar')),
                                          PopupMenuItem(value: 'excluir', child: Text('Eliminar')),
                                        ],
                                        icon: const Icon(Icons.more_vert),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
                if (!isMobile && state.totalCount != null)
                  EnterprisePagination(
                    page: state.page,
                    pageSize: state.pageSize,
                    totalCount: state.totalCount!,
                    itemLabel: 'terminais',
                    onPageChanged: controller.goToPage,
                    onPageSizeChanged: controller.setPageSize,
                    isBusy: state.isLoading,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final result = await showTerminalFormDialog(context);
    if (result == null || !context.mounted) return;
    try {
      await ref.read(terminalListProvider.notifier).create(result.payload);
      if (context.mounted) PharmaFeedback.success(context, 'Terminal criado');
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _openEdit(BuildContext context, TerminalDetalhe item) async {
    final result = await showTerminalFormDialog(context, terminal: item);
    if (result == null || !context.mounted) return;
    try {
      await ref.read(terminalListProvider.notifier).update(item.id, result.payload);
      if (context.mounted) PharmaFeedback.success(context, 'Terminal actualizado');
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _confirmDelete(BuildContext context, TerminalDetalhe item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar terminal'),
        content: Text('Deseja eliminar o terminal "${item.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(terminalListProvider.notifier).delete(item.id);
      if (context.mounted) PharmaFeedback.success(context, 'Terminal eliminado');
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }
}

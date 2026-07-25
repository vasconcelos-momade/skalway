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
import '../../domain/entities/printer.dart';
import '../../services/default_printer_service.dart';
import '../providers/printer_list_provider.dart';
import '../widgets/printer_form_dialog.dart';

class PrintersPage extends ConsumerStatefulWidget {
  const PrintersPage({super.key});

  @override
  ConsumerState<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends ConsumerState<PrintersPage> {
  final _searchController = TextEditingController();
  List<PrinterDetalhe> _accumulatedItems = [];
  String? _defaultPrinterId;

  @override
  void initState() {
    super.initState();
    _loadDefaultId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultId() async {
    final id =
        await ref.read(defaultPrinterServiceProvider).readDefaultPrinterId();
    if (!mounted) return;
    setState(() => _defaultPrinterId = id);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final state = ref.watch(printerListProvider);
    final controller = ref.read(printerListProvider.notifier);

    if (_searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    ref.listen(printerListProvider, (prev, next) {
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
                  onPressed:
                      state.isLoading ? null : () => _openCreate(context),
                  child: const Icon(Icons.add),
                )
              : null,
          body: EnterpriseModuleHub(
            title: 'Impressoras',
            subtitle: 'ESC/POS, rede, PDF e teste de impressão.',
            tag: AppNavSections.system,
            actions: isMobile
                ? null
                : [
                    OutlinedButton.icon(
                      onPressed:
                          state.isLoading ? null : controller.refreshCurrentPage,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Atualizar'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          state.isLoading ? null : () => _openCreate(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova impressora'),
                    ),
                  ],
            child: Column(
              children: [
                if (state.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: s.sm),
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context)
                          .textTheme
                          .erpBodySecondary
                          .copyWith(color: t.posDanger),
                    ),
                  ),
                Expanded(
                  child: state.isLoading && !state.isInitialized
                      ? const ModuleLoadingState()
                      : state.isInitialized &&
                              state.items.isEmpty &&
                              state.errorMessage == null
                          ? const ModuleEmptyState(
                              title: 'Nenhuma impressora configurada',
                              subtitle:
                                  'Crie uma impressora NETWORK (porta 9100) ou Bluetooth para o PDV.',
                            )
                          : isMobile
                              ? _buildMobile(context, t, state, controller)
                              : _buildDesktop(context, t, state, controller),
                ),
                if (!isMobile && state.totalCount != null)
                  EnterprisePagination(
                    page: state.page,
                    pageSize: state.pageSize,
                    totalCount: state.totalCount!,
                    itemLabel: 'impressoras',
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

  Widget _buildMobile(
    BuildContext context,
    PharmaTokens t,
    PrinterListState state,
    PrinterListController controller,
  ) {
    return EnterpriseMobileScrollList(
      stickyHeader: EnterpriseMobileToolbar(
        searchController: _searchController,
        searchHint: 'Nome, IP ou modelo...',
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
        final isDefault = item.id == _defaultPrinterId;
        return EnterpriseListCard(
          leading: Icons.print_outlined,
          title: item.name,
          subtitle: '${item.type} · ${item.addressSummary}',
          chip: EnterpriseStatusChip(
            label: isDefault
                ? 'Predefinida'
                : (item.active ? 'Activa' : 'Inactiva'),
            color: isDefault
                ? t.brandGreen
                : (item.active ? t.brandBlue : t.textMuted),
          ),
          metadata: [
            if (item.model != null)
              EnterpriseListCardMeta(label: 'Modelo: ${item.model}'),
            if (item.manufacturer != null)
              EnterpriseListCardMeta(
                label: 'Fabricante: ${item.manufacturer}',
              ),
          ],
          onTap: () => _openEdit(context, item),
        );
      },
      hasMore: state.hasMore,
      isLoading: state.isLoading,
      onLoadMore: () => controller.goToPage(state.page + 1),
      emptyMessage: 'Nenhuma impressora encontrada',
      totalCount: state.totalCount,
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    PharmaTokens t,
    PrinterListState state,
    PrinterListController controller,
  ) {
    return EnterpriseDataTable(
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('NOME')),
        DataColumn(label: Text('TIPO')),
        DataColumn(label: Text('LIGAÇÃO')),
        DataColumn(label: Text('ENDEREÇO')),
        DataColumn(label: Text('ESTADO')),
        DataColumn(label: Text('AÇÕES')),
      ],
      rowCount: state.items.length,
      rowBuilder: (context, index) {
        final item = state.items[index];
        final isDefault = item.id == _defaultPrinterId;
        return DataRow(
          cells: [
            DataCell(Text(item.name)),
            DataCell(Text(item.type)),
            DataCell(Text(item.connection)),
            DataCell(Text(item.addressSummary)),
            DataCell(
              Text(
                isDefault
                    ? 'Predefinida'
                    : (item.active ? 'Activa' : 'Inactiva'),
                style: Theme.of(context).textTheme.erpLabel.copyWith(
                      color: isDefault
                          ? t.brandGreen
                          : (item.active ? t.textPrimary : t.textMuted),
                    ),
              ),
            ),
            DataCell(
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'editar':
                      _openEdit(context, item);
                    case 'testar':
                      _testPrinter(context, item);
                    case 'predefinida':
                      _setDefault(context, item);
                    case 'excluir':
                      _confirmDelete(context, item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  const PopupMenuItem(
                    value: 'testar',
                    child: Text('Testar impressão'),
                  ),
                  if (item.isNetwork || item.isBluetooth)
                    const PopupMenuItem(
                      value: 'predefinida',
                      child: Text('Definir predefinida'),
                    ),
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Text('Eliminar'),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final result = await showPrinterFormDialog(context);
    if (result == null || !context.mounted) return;
    try {
      await ref.read(printerListProvider.notifier).create(result.payload);
      if (context.mounted) {
        PharmaFeedback.success(context, 'Impressora criada');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _openEdit(BuildContext context, PrinterDetalhe item) async {
    final result = await showPrinterFormDialog(context, printer: item);
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(printerListProvider.notifier)
          .update(item.id, result.payload);
      if (context.mounted) {
        PharmaFeedback.success(context, 'Impressora actualizada');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _testPrinter(BuildContext context, PrinterDetalhe item) async {
    try {
      await ref.read(printerListProvider.notifier).testPrinter(
            item.id,
            message: 'Teste Skalway Health — ${item.name}',
          );
      if (context.mounted) {
        PharmaFeedback.success(context, 'Teste enfileirado');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _setDefault(BuildContext context, PrinterDetalhe item) async {
    try {
      await ref.read(defaultPrinterServiceProvider).setDefault(item);
      if (!context.mounted) return;
      setState(() => _defaultPrinterId = item.id);
      PharmaFeedback.success(
        context,
        'Impressora "${item.name}" definida como predefinida',
      );
    } catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(
          context,
          e is StateError ? e.message : e.toString(),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PrinterDetalhe item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar impressora'),
        content: Text('Deseja eliminar a impressora "${item.name}"?'),
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
      await ref.read(printerListProvider.notifier).delete(item.id);
      if (_defaultPrinterId == item.id) {
        await ref.read(defaultPrinterServiceProvider).clearDefault();
        if (mounted) setState(() => _defaultPrinterId = null);
      }
      if (context.mounted) {
        PharmaFeedback.success(context, 'Impressora eliminada');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }
}

import 'package:flutter/material.dart';

import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/inputs/enterprise_search_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../categories/domain/entities/category.dart';
import '../providers/estoque_provider.dart';

class EstoqueToolbar extends StatefulWidget {
  const EstoqueToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.controller,
    required this.categories,
    required this.fornecedores,
    required this.onSearchChanged,
    required this.onOpenMobileFilters,
    this.trailingActions = const [],
  });

  final TextEditingController searchController;
  final EstoqueListState state;
  final EstoqueListController controller;
  final List<Category> categories;
  final List<({String id, String nome})> fornecedores;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenMobileFilters;
  final List<Widget> trailingActions;

  @override
  State<EstoqueToolbar> createState() => _EstoqueToolbarState();
}

class _EstoqueToolbarState extends State<EstoqueToolbar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EstoqueToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchChanged);
      widget.searchController.addListener(_onSearchChanged);
    }
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.pharmaScreen;
    if (screen == PharmaScreenSize.mobile) {
      return IgnorePointer(
        ignoring: widget.state.isLoading,
        child: EnterpriseSearchField(
          controller: widget.searchController,
          hintText: 'Produto, código ou lote...',
          onChanged: widget.onSearchChanged,
        ),
      );
    }

    final state = widget.state;

    return EnterpriseDesktopListToolbar(
      searchController: widget.searchController,
      searchHint: 'Pesquisar produto, código de barras ou lote...',
      isLoading: widget.state.isLoading,
      onSearchSubmitted: widget.onSearchChanged,
      hasFilters: widget.state.hasFilters,
      onClearFilters: widget.state.isLoading ? null : widget.controller.clearFilters,
      trailingActions: widget.trailingActions,
      filterWidgets: [
        SizedBox(
          width: 170,
          child: EnterpriseSelectField<String>(
            key: ValueKey('estoque-cat-${state.categoriaId}'),
            label: 'Categoria',
            emptyLabel: 'Todas',
            value: state.categoriaId,
            options: [
              for (final c in widget.categories)
                EnterpriseSelectOption<String>(value: c.id, label: c.nome),
            ],
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setCategoriaFilter,
          ),
        ),
        SizedBox(
          width: 170,
          child: EnterpriseSelectField<String>(
            key: ValueKey('estoque-forn-${state.fornecedorId}'),
            label: 'Fornecedor',
            emptyLabel: 'Todos',
            value: state.fornecedorId,
            options: [
              for (final f in widget.fornecedores)
                EnterpriseSelectOption<String>(value: f.id, label: f.nome),
            ],
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setFornecedorFilter,
          ),
        ),
        SizedBox(
          width: 160,
          child: EnterpriseSelectField<String>(
            key: ValueKey('estoque-estado-${state.estadoSanitario}'),
            label: 'Estado sanitário',
            emptyLabel: 'Todos',
            value: state.estadoSanitario,
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
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setEstadoSanitarioFilter,
          ),
        ),
        SizedBox(
          width: 150,
          child: EnterpriseSelectField<String>(
            key: ValueKey('estoque-disp-${state.disponibilidade}'),
            label: 'Disponibilidade',
            emptyLabel: 'Todas',
            value: state.disponibilidade,
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
            onChanged: widget.state.isLoading
                ? null
                : widget.controller.setDisponibilidadeFilter,
          ),
        ),
      ],
    );
  }
}

class EstoqueMobileToolbar extends StatelessWidget {
  const EstoqueMobileToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.controller,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.reportAction,
  });

  final TextEditingController searchController;
  final EstoqueListState state;
  final EstoqueListController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final Widget reportAction;

  @override
  Widget build(BuildContext context) {
    return EnterpriseMobileToolbar(
      searchController: searchController,
      searchHint: 'Produto, código ou lote...',
      enabled: !state.isLoading,
      isLoading: state.isLoading,
      hasFilters: state.hasFilters,
      reportAction: reportAction,
      onSearchSubmitted: onSearchChanged,
      onOpenFilters: onOpenFilters,
      onClearFilters: () async => controller.clearFilters(),
      onRefresh: controller.refreshCurrentPage,
    );
  }
}

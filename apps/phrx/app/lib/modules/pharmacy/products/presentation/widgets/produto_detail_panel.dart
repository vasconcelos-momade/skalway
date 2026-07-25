import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../domain/entities/product.dart';
import '../../domain/produto_dispensacao.dart';
import 'detail/lot_card.dart';
import 'detail/movement_timeline.dart';
import 'detail/product_header.dart';
import 'detail/property_tile.dart';
import 'detail/regulation_card.dart';
import 'detail/section_card.dart';
import 'detail/status_badge.dart';

class ProdutoDetailPanel extends ConsumerStatefulWidget {
  const ProdutoDetailPanel({
    super.key,
    required this.product,
    required this.onClose,
    this.onEdit,
    this.onDelete,
  });

  final Product product;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  ConsumerState<ProdutoDetailPanel> createState() => _ProdutoDetailPanelState();
}

class _ProdutoDetailPanelState extends ConsumerState<ProdutoDetailPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  var _loading = true;
  Product? _detail;
  List<Map<String, dynamic>> _lotes = [];
  List<Map<String, dynamic>> _movimentos = [];
  List<Map<String, dynamic>> _precos = [];
  List<Map<String, dynamic>> _historico = [];
  List<Map<String, dynamic>> _fornecedores = [];
  List<Map<String, dynamic>> _auditoria = [];


  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    final productsDs = ref.read(productRemoteDataSourceProvider);
    try {
      final productResponse = await productsDs.getProduct(widget.product.id);
      final lotesRes = await dio.get<dynamic>(
        ApiConstants.tenantProdutoLotes(widget.product.id),
      );
      final movRes = await dio.get<Map<String, dynamic>>(
        ApiConstants.tenantStockMovements,
        queryParameters: {'produtoId': widget.product.id, 'pageSize': 20},
      );
      final precosRes = await dio.get<Map<String, dynamic>>(
        ApiConstants.tenantProdutoHistoricoPrecos(widget.product.id),
      );
      final historicoRes = await productsDs.listHistory(id: widget.product.id);
      final fornecedoresRes = await productsDs.listSuppliers(widget.product.id);
      final auditoriaRes = await productsDs.listAudit(id: widget.product.id);

      if (!mounted) return;
      setState(() {
        _detail = _mapProduct(productResponse);
        _lotes = _unwrapList(lotesRes.data);
        _movimentos = ApiEnvelope.unwrapMap(movRes.data!).letItems();
        _precos = ApiEnvelope.unwrapMap(precosRes.data!).letItems();
        _historico = historicoRes.items;
        _fornecedores = fornecedoresRes;
        _auditoria = auditoriaRes.items;
        _loading = false;
      });
    } on DioException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Product _mapProduct(ProductModel model) {
    return Product(
      id: model.id,
      nomeComercial: model.nomeComercial,
      nomeGenerico: model.nomeGenerico,
      dosagem: model.dosagem,
      forma: model.forma,
      apresentacao: model.apresentacao,
      ativo: model.ativo,
      barcode: model.barcode,
      categoriaId: model.categoriaId,
      categoriaNome: model.categoriaNome,
      categoriaCodigoFnm: model.categoriaCodigoFnm,
      tipoDispensacao: model.tipoDispensacao,
      requiresPrescription: model.requiresPrescription,
      requiresDoubleCheck: model.requiresDoubleCheck,
      requiresPsychotropicBook: model.requiresPsychotropicBook,
      antimicrobiano: model.antimicrobiano,
      requiresManualReview: model.requiresManualReview,
      precoVenda: model.precoVenda,
      estoqueAtual: model.estoqueAtual,
      estoqueMinimo: model.estoqueMinimo,
      numLotes: model.numLotes,
      lote: model.lote,
      dataValidade: model.dataValidade,
      proximaValidade: model.proximaValidade,
      createdAt: model.createdAt,
      taxRule: model.taxRule,
    );
  }

  List<Map<String, dynamic>> _unwrapList(dynamic payload) {
    if (payload is List) {
      return payload.cast<Map<String, dynamic>>();
    }
    if (payload is Map) {
      return ApiEnvelope.unwrapList(payload).cast<Map<String, dynamic>>();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final product = _detail ?? widget.product;
    final isMobile = AdaptiveNavigator.isMobile(context);
    final body = _buildBody(context, product);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(shortProductName(product.nomeComercial)),
          actions: [_buildActionsMenu(context)],
        ),
        body: body,
      );
    }

    return body;
  }

  Widget _buildBody(BuildContext context, Product product) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductHeader(
          product: product,
          showClose: !AdaptiveNavigator.isMobile(context),
          onClose: widget.onClose,
        ),
        Material(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorWeight: 2,
            dividerHeight: 1,
            dividerColor: t.border.withValues(alpha: 0.35),
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            tabs: [
              const Tab(text: 'Geral'),
              const Tab(text: 'Regulação'),
              Tab(text: _tabWithCount('Lotes', _lotes.length)),
              Tab(text: _tabWithCount('Movimentos', _movimentos.length)),
              Tab(text: _tabWithCount('Preços', _precos.length)),
              Tab(text: _tabWithCount('Histórico', _historico.length)),
              Tab(text: _tabWithCount('Fornecedor', _fornecedores.length)),
              Tab(text: _tabWithCount('Auditoria', _auditoria.length)),
            ],
          ),
        ),
        if (_loading)
          LinearProgressIndicator(
            minHeight: 2,
            color: t.brandBlue,
            backgroundColor: t.border.withValues(alpha: 0.2),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _GeneralTab(product: product),
              _RegulationTab(product: product),
              _LotesTab(lotes: _lotes, loading: _loading),
              MovementTimeline(movimentos: _movimentos),
              _SimpleListTab(
                empty: 'Sem histórico de preços',
                items: _precos
                    .map(
                      (p) =>
                          '${p['precoAnterior']} → ${p['precoNovo']} (${_formatDate(p['data'])})',
                    )
                    .toList(),
              ),
              _SimpleListTab(
                empty: 'Sem histórico regulatório',
                items: _historico
                    .map(
                      (item) =>
                          '${item['rule'] ?? 'Regra'} • ${item['source'] ?? 'manual'} (${_formatDate(item['createdAt'])})',
                    )
                    .toList(),
              ),
              _SimpleListTab(
                empty: 'Sem fornecedores vinculados',
                items: _fornecedores
                    .map(
                      (item) =>
                          '${item['fornecedor']?['nome'] ?? 'Fornecedor'} • compra ${item['precoCompra'] ?? 0}${item['fornecedorPrincipal'] == true ? ' • principal' : ''}',
                    )
                    .toList(),
              ),
              _SimpleListTab(
                empty: 'Sem auditoria',
                items: _auditoria
                    .map(
                      (item) =>
                          '${item['action'] ?? 'Evento'} • ${item['user']?['nome'] ?? 'Sistema'} (${_formatDate(item['createdAt'])})',
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        if (!AdaptiveNavigator.isMobile(context))
          Padding(
            padding: EdgeInsets.all(s.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: widget.onClose, child: const Text('Fechar')),
            ),
          ),
      ],
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case 'editar':
            widget.onEdit?.call();
          case 'excluir':
            widget.onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        if (widget.onEdit != null)
          const PopupMenuItem(value: 'editar', child: Text('Editar')),
        if (widget.onDelete != null)
          const PopupMenuItem(value: 'excluir', child: Text('Eliminar')),
      ],
    );
  }

  String _tabWithCount(String label, int count) {
    if (count <= 0) return label;
    return '$label ($count)';
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '—';
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return ListView(
      padding: EdgeInsets.all(s.md),
      children: [
        SectionCard(
          title: 'Identificação',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PropertyTile(label: 'Nome genérico', value: product.nomeGenerico),
              PropertyTile(label: 'Dosagem', value: product.dosagem),
              PropertyTile(label: 'Forma', value: product.forma),
              PropertyTile(label: 'Apresentação', value: product.apresentacao),
              PropertyTile(label: 'Código de barras', value: product.barcode),
            ],
          ),
        ),
        SectionCard(
          title: 'Stock',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PropertyTile(
                label: 'Stock disponível',
                value: _formatNumber(product.estoqueAtual),
                expandable: false,
              ),
              PropertyTile(
                label: 'Estoque mínimo',
                value: _formatNumber(product.estoqueMinimo),
                expandable: false,
              ),
              PropertyTile(
                label: 'Nº lotes',
                value: product.numLotes.toString(),
                expandable: false,
              ),
              PropertyTile(
                label: 'Próxima validade',
                value: product.proximaValidade?.toString().substring(0, 10),
                expandable: false,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Estado',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Situação do produto',
                style: Theme.of(context).textTheme.erpCaption.copyWith(
                      color: context.pharmaTokens.textMuted,
                    ),
              ),
              const SizedBox(height: 8),
              StatusBadge(active: product.ativo),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _RegulationTab extends StatelessWidget {
  const _RegulationTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return ListView(
      padding: EdgeInsets.all(s.md),
      children: [
        RegulationCard(
          title: 'Tipo de dispensação',
          items: [
            RegulationItem(
              label: produtoTipoDispensacaoLabel(product.tipoDispensacao),
              enabled: true,
            ),
            RegulationItem(
              label: produtoDispensacaoDerivedSummary(product.tipoDispensacao),
              enabled: product.tipoDispensacao != 'VENDA_LIVRE',
            ),
          ],
        ),
        RegulationCard(
          title: 'Livros regulatórios',
          items: [
            RegulationItem(
              label: 'Livro de Receitas',
              enabled: product.requiresPrescription,
            ),
            RegulationItem(
              label: 'Livro de Psicotrópicos',
              enabled: product.requiresPsychotropicBook,
            ),
          ],
        ),
        RegulationCard(
          title: 'Regras derivadas (calculadas)',
          items: [
            RegulationItem(
              label: 'Dupla verificação',
              enabled: product.requiresDoubleCheck,
            ),
            RegulationItem(
              label: 'Antimicrobiano (categoria FNM)',
              enabled: product.antimicrobiano,
            ),
          ],
        ),
      ],
    );
  }
}

class _LotesTab extends StatelessWidget {
  const _LotesTab({required this.lotes, required this.loading});

  final List<Map<String, dynamic>> lotes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    if (!loading && lotes.isEmpty) {
      return Center(
        child: Text(
          'Sem lotes',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                color: context.pharmaTokens.textMuted,
              ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemCount: lotes.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (_, index) => LotCard(lote: lotes[index]),
    );
  }
}

class _SimpleListTab extends StatelessWidget {
  const _SimpleListTab({required this.empty, required this.items});

  final String empty;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (items.isEmpty) {
      return Center(
        child: Text(
          empty,
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                color: t.textMuted,
              ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: t.border.withValues(alpha: 0.35)),
      itemBuilder: (_, index) => Padding(
        padding: EdgeInsets.symmetric(vertical: s.sm),
        child: Text(
          items[index],
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                color: t.textPrimary,
              ),
        ),
      ),
    );
  }
}

extension on Map<String, dynamic> {
  List<Map<String, dynamic>> letItems() {
    return (this['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
  }
}

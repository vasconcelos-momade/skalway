import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/routes.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../regulatory/data/datasources/regulatory_remote_datasource.dart';

enum RecipesBookTab { receitas, book }

class RecipesBookPage extends ConsumerStatefulWidget {
  const RecipesBookPage({super.key, this.initialTab = RecipesBookTab.receitas});

  final RecipesBookTab initialTab;

  @override
  ConsumerState<RecipesBookPage> createState() => _RecipesBookPageState();
}

class _RecipesBookPageState extends ConsumerState<RecipesBookPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _receitasSearchController;
  late final TextEditingController _livroSearchController;
  Timer? _refreshTimer;

  bool _loadingReceitas = true;
  bool _loadingLivro = true;
  String? _receitasError;
  String? _livroError;

  Map<String, dynamic>? _receitasDashboard;
  List<Map<String, dynamic>> _receitasItems = <Map<String, dynamic>>[];
  int _receitasPage = 1;
  int _receitasPageSize = PaginationDefaults.pageSize;
  bool _receitasHasMore = false;
  int _receitasTotal = 0;
  String _receitasSearch = '';
  String? _receitasStatus;
  String? _receitasOrigem;
  final String _receitasSortBy = 'dataReceita';
  final String _receitasSortDir = 'desc';

  Map<String, dynamic>? _livroDashboard;
  List<Map<String, dynamic>> _livroItems = <Map<String, dynamic>>[];
  int _livroPage = 1;
  int _livroPageSize = PaginationDefaults.pageSize;
  bool _livroHasMore = false;
  int _livroTotal = 0;
  String _livroSearch = '';
  String? _livroOrigem;
  String? _livroTipoMovimento;
  final String _livroSortBy = 'createdAt';
  final String _livroSortDir = 'desc';

  RegulatoryRemoteDataSource get _ds =>
      ref.read(regulatoryRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == RecipesBookTab.book ? 1 : 0,
    );
    _receitasSearchController = TextEditingController();
    _livroSearchController = TextEditingController();
    _bootstrap();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _reloadCurrentTab(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _receitasSearchController.dispose();
    _livroSearchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadReceitas(), _loadLivro()]);
  }

  Future<void> _reloadCurrentTab({bool silent = false}) async {
    if (_tabController.index == 0) {
      await _loadReceitas(silent: silent);
    } else {
      await _loadLivro(silent: silent);
    }
  }

  Future<void> _loadReceitas({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadingReceitas = true;
        _receitasError = null;
      });
    }

    try {
      final results = await Future.wait([
        _ds.receitasDashboard(
          search: _receitasSearch.isEmpty ? null : _receitasSearch,
        ),
        _ds.listReceitas(
          search: _receitasSearch.isEmpty ? null : _receitasSearch,
          status: _receitasStatus,
          origem: _receitasOrigem,
          sortBy: _receitasSortBy,
          sortDir: _receitasSortDir,
          page: _receitasPage,
          pageSize: _receitasPageSize,
        ),
      ]);
      final page = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        _receitasDashboard = results[0] as Map<String, dynamic>;
        _receitasItems = page.items.cast<Map<String, dynamic>>();
        _receitasPage = page.page as int;
        _receitasPageSize = page.pageSize as int;
        _receitasHasMore = page.hasMore as bool;
        _receitasTotal = (page.totalCount as int?) ?? _receitasItems.length;
        _loadingReceitas = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReceitas = false;
        _receitasError = error.toString();
      });
    }
  }

  Future<void> _loadLivro({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadingLivro = true;
        _livroError = null;
      });
    }

    try {
      final results = await Future.wait([
        _ds.livroReceitasDashboard(
          search: _livroSearch.isEmpty ? null : _livroSearch,
          origem: _livroOrigem,
          tipoMovimento: _livroTipoMovimento,
        ),
        _ds.listLivroReceitas(
          search: _livroSearch.isEmpty ? null : _livroSearch,
          origem: _livroOrigem,
          tipoMovimento: _livroTipoMovimento,
          sortBy: _livroSortBy,
          sortDir: _livroSortDir,
          page: _livroPage,
          pageSize: _livroPageSize,
        ),
      ]);
      final page = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        _livroDashboard = results[0] as Map<String, dynamic>;
        _livroItems = page.items.cast<Map<String, dynamic>>();
        _livroPage = page.page as int;
        _livroPageSize = page.pageSize as int;
        _livroHasMore = page.hasMore as bool;
        _livroTotal = (page.totalCount as int?) ?? _livroItems.length;
        _loadingLivro = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLivro = false;
        _livroError = error.toString();
      });
    }
  }

  Future<void> _openReceitaDetail(String id) async {
    await AdaptiveNavigator.openPanel<void>(
      context: context,
      sideSheetWidth: 920,
      builder: (panelContext) => SizedBox(
        width: 920,
        height: 680,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _ds.getReceita(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final data = snapshot.data ?? const <String, dynamic>{};
            return _DetailScaffold(
              title: data['numeroReceita']?.toString() ?? 'Receita',
              onClose: () => AdaptiveNavigator.close(panelContext),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoTile(
                        label: 'Paciente',
                        value: data['cliente']?['nome']?.toString() ?? '—',
                      ),
                      _InfoTile(
                        label: 'Médico',
                        value: data['medicoNome']?.toString() ?? '—',
                      ),
                      _InfoTile(
                        label: 'Estado',
                        value: data['status']?.toString() ?? '—',
                      ),
                      _InfoTile(
                        label: 'Origem',
                        value: data['origem']?.toString() ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dispensações',
                    style: Theme.of(context).textTheme.erpBodyStrong,
                  ),
                  const SizedBox(height: 8),
                  ...(data['dispensacoes'] as List<dynamic>? ?? const []).map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item['produto']?['nome']?.toString() ?? 'Produto',
                      ),
                      subtitle: Text(
                        'Qtd: ${item['quantidade']} • ${item['tipoDispensacao']}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Histórico',
                    style: Theme.of(context).textTheme.erpBodyStrong,
                  ),
                  const SizedBox(height: 8),
                  ...(data['timeline'] as List<dynamic>? ?? const []).map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['description']?.toString() ?? '—'),
                      subtitle: Text(item['at']?.toString() ?? '—'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openLivroDetail(String id) async {
    await AdaptiveNavigator.openPanel<void>(
      context: context,
      sideSheetWidth: 860,
      builder: (panelContext) => SizedBox(
        width: 860,
        height: 640,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _ds.getLivroReceita(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final data = snapshot.data ?? const <String, dynamic>{};
            return _DetailScaffold(
              title: 'Movimento ${data['numeroReceita'] ?? data['id']}',
              onClose: () => AdaptiveNavigator.close(panelContext),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoTile(
                        label: 'Paciente',
                        value: data['cliente']?['nome']?.toString() ?? '—',
                      ),
                      _InfoTile(
                        label: 'Produto',
                        value: data['produto']?['nome']?.toString() ?? '—',
                      ),
                      _InfoTile(
                        label: 'Movimento',
                        value: data['tipoMovimento']?.toString() ?? '—',
                      ),
                      _InfoTile(
                        label: 'Origem',
                        value: data['origemReceita']?.toString() ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Auditoria',
                    style: Theme.of(context).textTheme.erpBodyStrong,
                  ),
                  const SizedBox(height: 8),
                  ...(data['auditLogs'] as List<dynamic>? ?? const []).map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['action']?.toString() ?? '—'),
                      subtitle: Text(item['createdAt']?.toString() ?? '—'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openReceitaForm([Map<String, dynamic>? item]) async {
    final clienteId = TextEditingController(
      text: item?['clienteId']?.toString() ?? '',
    );
    final numero = TextEditingController(
      text: item?['numeroReceita']?.toString() ?? '',
    );
    final medico = TextEditingController(
      text: item?['medicoNome']?.toString() ?? '',
    );
    final unidade = TextEditingController(
      text: item?['unidadeSanitaria']?.toString() ?? '',
    );
    final data = TextEditingController(
      text:
          item?['dataReceita']?.toString().substring(0, 10) ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
    final observacoes = TextEditingController(
      text: item?['observacoes']?.toString() ?? '',
    );

    final saved = await AdaptiveNavigator.openForm<bool>(
      context: context,
      title: Text(item == null ? 'Nova receita' : 'Editar receita'),
      contentBuilder: (formContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: clienteId,
              decoration: const InputDecoration(labelText: 'Cliente ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numero,
              decoration: const InputDecoration(labelText: 'Número da receita'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: medico,
              decoration: const InputDecoration(labelText: 'Médico'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unidade,
              decoration: const InputDecoration(labelText: 'Unidade sanitária'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: data,
              decoration: const InputDecoration(labelText: 'Data (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: observacoes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      AdaptiveNavigator.complete(formContext, false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final body = <String, dynamic>{
                      'clienteId': clienteId.text.trim(),
                      'numeroReceita': numero.text.trim().isEmpty
                          ? null
                          : numero.text.trim(),
                      'medicoNome': medico.text.trim().isEmpty
                          ? null
                          : medico.text.trim(),
                      'unidadeSanitaria': unidade.text.trim().isEmpty
                          ? null
                          : unidade.text.trim(),
                      'dataReceita': data.text.trim(),
                      'observacoes': observacoes.text.trim().isEmpty
                          ? null
                          : observacoes.text.trim(),
                    };
                    try {
                      if (item == null) {
                        await _ds.createReceita(body);
                      } else {
                        await _ds.updateReceita(item['id'].toString(), body);
                      }
                      if (!formContext.mounted) return;
                      AdaptiveNavigator.complete(formContext, true);
                    } catch (error) {
                      if (!formContext.mounted) return;
                      PharmaFeedback.error(formContext, error.toString());
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        );
      },
    );

    clienteId.dispose();
    numero.dispose();
    medico.dispose();
    unidade.dispose();
    data.dispose();
    observacoes.dispose();

    if (saved == true) {
      await _loadReceitas();
    }
  }

  Future<void> _deleteReceita(Map<String, dynamic> item) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Remover receita',
      message:
          'Deseja remover a receita ${item['numeroReceita'] ?? item['id']}?',
      confirmText: 'Remover',
      cancelText: 'Cancelar',
      destructive: true,
    );

    if (confirmed != true) return;
    try {
      await _ds.deleteReceita(item['id'].toString());
      await _loadReceitas();
    } catch (error) {
      if (!mounted) return;
      PharmaFeedback.error(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final showingLivro = _tabController.index == 1;
    final receitasKpis = _receitasDashboard == null
        ? <EnterpriseStatCard>[]
        : [
            EnterpriseStatCard(
              title: 'Emitidas',
              value: '${_receitasDashboard!['kpis']?['emitidas'] ?? 0}',
              icon: Icons.description_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Utilizadas',
              value: '${_receitasDashboard!['kpis']?['utilizadas'] ?? 0}',
              icon: Icons.check_circle_outline,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Pendentes',
              value: '${_receitasDashboard!['kpis']?['pendentes'] ?? 0}',
              icon: Icons.pending_actions_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Expiradas',
              value: '${_receitasDashboard!['kpis']?['expiradas'] ?? 0}',
              icon: Icons.event_busy_outlined,
              density: StatCardDensity.compact,
            ),
          ];
    final livroKpis = _livroDashboard == null
        ? <EnterpriseStatCard>[]
        : [
            EnterpriseStatCard(
              title: 'Movimentos',
              value: '${_livroDashboard!['kpis']?['totalMovimentos'] ?? 0}',
              icon: Icons.menu_book_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Entradas',
              value: '${_livroDashboard!['kpis']?['entradas'] ?? 0}',
              icon: Icons.call_received_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Saídas',
              value: '${_livroDashboard!['kpis']?['saidas'] ?? 0}',
              icon: Icons.call_made_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Pacientes',
              value: '${_livroDashboard!['kpis']?['pacientesUnicos'] ?? 0}',
              icon: Icons.people_outline,
              density: StatCardDensity.compact,
            ),
          ];
    final hubKpis = showingLivro ? livroKpis : receitasKpis;

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return EnterpriseModuleHub(
          title: showingLivro ? 'Livro de Receitas' : 'Receitas',
          subtitle: showingLivro
              ? 'Movimentos oficiais de livro de receitas com rastreio, auditoria e exportação.'
              : 'Receitas reais do backend com dispensa rastreável, conformidade e histórico clínico.',
          tag: 'Regulatório',
          mobileKpisHorizontalScroll: true,
          actions: isMobile
              ? null
              : [
                  IconButton(
                    onPressed: () => _reloadCurrentTab(),
                    icon: const Icon(Icons.refresh),
                  ),
                  if (_tabController.index == 0)
                    FilledButton.icon(
                      onPressed: _openReceitaForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Nova receita'),
                    ),
                ],
          kpis: isMobile ? null : (hubKpis.isEmpty ? null : hubKpis),
          filters: isMobile
              ? null
              : (_tabController.index == 0
                    ? _buildReceitasFilters(context)
                    : _buildLivroFilters(context)),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  final targetPath = index == 0
                      ? AppRoutePaths.recipes
                      : AppRoutePaths.recipesBook;
                  if (GoRouterState.of(context).uri.path != targetPath) {
                    context.go(targetPath);
                  } else {
                    setState(() {});
                  }
                },
                tabs: const [
                  Tab(text: 'Receitas'),
                  Tab(text: 'Livro de receitas'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceitasTab(
                      context,
                      isMobile: isMobile,
                      kpis: receitasKpis,
                    ),
                    _buildLivroTab(
                      context,
                      isMobile: isMobile,
                      kpis: livroKpis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceitasFilters(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _receitasSearchController,
            decoration: const InputDecoration(
              hintText: 'Número, médico, paciente...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              setState(() {
                _receitasSearch = value.trim();
                _receitasPage = 1;
              });
              _loadReceitas();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _receitasStatus,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'PENDENTE', child: Text('Pendente')),
              DropdownMenuItem(value: 'UTILIZADA', child: Text('Utilizada')),
              DropdownMenuItem(value: 'EXPIRADA', child: Text('Expirada')),
            ],
            onChanged: (value) {
              setState(() {
                _receitasStatus = value;
                _receitasPage = 1;
              });
              _loadReceitas();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _receitasOrigem,
            decoration: const InputDecoration(
              labelText: 'Origem',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: 'FISICA', child: Text('Física')),
              DropdownMenuItem(value: 'DIGITAL', child: Text('Digital')),
              DropdownMenuItem(
                value: 'SISTEMA_INTERNO',
                child: Text('Sistema'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _receitasOrigem = value;
                _receitasPage = 1;
              });
              _loadReceitas();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLivroFilters(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _livroSearchController,
            decoration: const InputDecoration(
              hintText: 'Receita, paciente, produto...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              setState(() {
                _livroSearch = value.trim();
                _livroPage = 1;
              });
              _loadLivro();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _livroTipoMovimento,
            decoration: const InputDecoration(
              labelText: 'Movimento',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
              DropdownMenuItem(value: 'SAIDA', child: Text('Saída')),
              DropdownMenuItem(
                value: 'CANCELAMENTO',
                child: Text('Cancelamento'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _livroTipoMovimento = value;
                _livroPage = 1;
              });
              _loadLivro();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _livroOrigem,
            decoration: const InputDecoration(
              labelText: 'Origem',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: 'FISICA', child: Text('Física')),
              DropdownMenuItem(value: 'DIGITAL', child: Text('Digital')),
              DropdownMenuItem(
                value: 'SISTEMA_INTERNO',
                child: Text('Sistema'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _livroOrigem = value;
                _livroPage = 1;
              });
              _loadLivro();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReceitasTab(
    BuildContext context, {
    bool isMobile = false,
    List<EnterpriseStatCard>? kpis,
  }) {
    final t = context.pharmaTokens;

    if (isMobile) {
      return EnterpriseMobileScrollList(
        kpis: kpis,
        errorText: _receitasError,
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _receitasSearchController,
          searchHint: 'Receita, paciente, médico...',
          enabled: !_loadingReceitas,
          isLoading: _loadingReceitas,
          hasFilters: _receitasStatus != null ||
              _receitasOrigem != null ||
              _receitasSearch.isNotEmpty,
          onSearchSubmitted: (value) {
            setState(() {
              _receitasSearch = value.trim();
              _receitasPage = 1;
            });
            _loadReceitas();
          },
          onOpenFilters: () {},
          onClearFilters: () async {
            setState(() {
              _receitasSearch = '';
              _receitasStatus = null;
              _receitasOrigem = null;
              _receitasPage = 1;
              _receitasSearchController.clear();
            });
            await _loadReceitas();
          },
          onRefresh: _loadReceitas,
        ),
        itemCount: _receitasItems.length,
        itemBuilder: (context, index) {
          final item = _receitasItems[index];
          return EnterpriseListCard(
            leading: Icons.description_outlined,
            title: item['numeroReceita']?.toString() ?? '—',
            subtitle: item['cliente']?['nome']?.toString() ?? '—',
            chip: EnterpriseStatusChip(
              label: item['status']?.toString() ?? '—',
            ),
            metadata: [
              EnterpriseListCardMeta(
                label: 'Médico: ${item['medicoNome']?.toString() ?? '—'}',
              ),
              EnterpriseListCardMeta(
                label:
                    'Data: ${item['dataReceita']?.toString().substring(0, 10) ?? '—'}',
              ),
            ],
            onTap: () => _openReceitaDetail(item['id'].toString()),
            actions: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _openReceitaForm(item);
                if (value == 'delete') _deleteReceita(item);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Remover')),
              ],
            ),
          );
        },
        hasMore: false,
        isLoading: _loadingReceitas,
        emptyMessage: 'Sem resultados para os filtros selecionados.',
        totalCount: _receitasTotal,
        totalCountLabel: 'receitas',
      );
    }

    return Column(
      children: [
        if (_loadingReceitas) const LinearProgressIndicator(),
        if (_receitasError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _receitasError!,
              style: Theme.of(
                context,
              ).textTheme.erpBody.copyWith(color: t.posDanger),
            ),
          ),
        Expanded(
          child: _receitasItems.isEmpty && !_loadingReceitas
              ? const Center(
                  child: Text('Sem resultados para os filtros selecionados.'),
                )
              : EnterpriseDataTable(
                  columns: const [
                    DataColumn(label: Text('RECEITA')),
                    DataColumn(label: Text('PACIENTE')),
                    DataColumn(label: Text('MÉDICO')),
                    DataColumn(label: Text('DATA')),
                    DataColumn(label: Text('ESTADO')),
                    DataColumn(label: Text('ACÇÕES')),
                  ],
                  rowCount: _receitasItems.length,
                  rowBuilder: (context, index) {
                    final item = _receitasItems[index];
                    return DataRow(
                      onSelectChanged: (_) =>
                          _openReceitaDetail(item['id'].toString()),
                      cells: [
                        DataCell(
                          Text(item['numeroReceita']?.toString() ?? '—'),
                        ),
                        DataCell(
                          Text(item['cliente']?['nome']?.toString() ?? '—'),
                        ),
                        DataCell(Text(item['medicoNome']?.toString() ?? '—')),
                        DataCell(
                          Text(
                            item['dataReceita']?.toString().substring(0, 10) ??
                                '—',
                          ),
                        ),
                        DataCell(
                          _StatusBadge(label: item['status']?.toString()),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _openReceitaForm(item),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () => _deleteReceita(item),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        MovimentacoesPagination(
          page: _receitasPage,
          pageSize: _receitasPageSize,
          hasMore: _receitasHasMore,
          isBusy: _loadingReceitas,
          totalCount: _receitasTotal,
          itemsOnPage: _receitasItems.length,
          onPageChanged: (nextPage) {
            setState(() => _receitasPage = nextPage);
            _loadReceitas();
          },
          onPageSizeChanged: (value) {
            setState(() {
              _receitasPageSize = value;
              _receitasPage = 1;
            });
            _loadReceitas();
          },
        ),
        Text(
          'Total: $_receitasTotal receita(s)',
          style: Theme.of(
            context,
          ).textTheme.erpCaption.copyWith(color: t.textMuted),
        ),
      ],
    );
  }

  Widget _buildLivroTab(
    BuildContext context, {
    bool isMobile = false,
    List<EnterpriseStatCard>? kpis,
  }) {
    final t = context.pharmaTokens;

    if (isMobile) {
      return EnterpriseMobileScrollList(
        kpis: kpis,
        errorText: _livroError,
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _livroSearchController,
          searchHint: 'Receita, paciente, produto...',
          enabled: !_loadingLivro,
          isLoading: _loadingLivro,
          hasFilters: _livroOrigem != null ||
              _livroTipoMovimento != null ||
              _livroSearch.isNotEmpty,
          onSearchSubmitted: (value) {
            setState(() {
              _livroSearch = value.trim();
              _livroPage = 1;
            });
            _loadLivro();
          },
          onOpenFilters: () {},
          onClearFilters: () async {
            setState(() {
              _livroSearch = '';
              _livroOrigem = null;
              _livroTipoMovimento = null;
              _livroPage = 1;
              _livroSearchController.clear();
            });
            await _loadLivro();
          },
          onRefresh: _loadLivro,
        ),
        itemCount: _livroItems.length,
        itemBuilder: (context, index) {
          final item = _livroItems[index];
          return EnterpriseListCard(
            leading: Icons.menu_book_outlined,
            title: item['produto']?['nome']?.toString() ?? '—',
            subtitle: item['numeroReceita']?.toString() ?? '—',
            chip: EnterpriseStatusChip(
              label: item['tipoMovimento']?.toString() ?? '—',
            ),
            metadata: [
              EnterpriseListCardMeta(
                label: 'Paciente: ${item['cliente']?['nome']?.toString() ?? '—'}',
              ),
              EnterpriseListCardMeta(
                label:
                    'Qtd: ${item['quantidade'] ?? 0} · Saldo: ${item['saldoAtual'] ?? 0}',
                emphasized: true,
              ),
            ],
            onTap: () => _openLivroDetail(item['id'].toString()),
          );
        },
        hasMore: false,
        isLoading: _loadingLivro,
        emptyMessage: 'Sem resultados para os filtros selecionados.',
        totalCount: _livroTotal,
        totalCountLabel: 'movimentos',
      );
    }

    return Column(
      children: [
        if (_loadingLivro) const LinearProgressIndicator(),
        if (_livroError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _livroError!,
              style: Theme.of(
                context,
              ).textTheme.erpBody.copyWith(color: t.posDanger),
            ),
          ),
        Expanded(
          child: _livroItems.isEmpty && !_loadingLivro
              ? const Center(
                  child: Text('Sem resultados para os filtros selecionados.'),
                )
              : EnterpriseDataTable(
                  columns: const [
                    DataColumn(label: Text('RECEITA')),
                    DataColumn(label: Text('PACIENTE')),
                    DataColumn(label: Text('PRODUTO')),
                    DataColumn(label: Text('QTD')),
                    DataColumn(label: Text('MOVIMENTO')),
                    DataColumn(label: Text('SALDO')),
                  ],
                  rowCount: _livroItems.length,
                  rowBuilder: (context, index) {
                    final item = _livroItems[index];
                    return DataRow(
                      onSelectChanged: (_) =>
                          _openLivroDetail(item['id'].toString()),
                      cells: [
                        DataCell(
                          Text(item['numeroReceita']?.toString() ?? '—'),
                        ),
                        DataCell(
                          Text(item['cliente']?['nome']?.toString() ?? '—'),
                        ),
                        DataCell(
                          Text(item['produto']?['nome']?.toString() ?? '—'),
                        ),
                        DataCell(Text('${item['quantidade'] ?? 0}')),
                        DataCell(
                          _StatusBadge(
                            label: item['tipoMovimento']?.toString(),
                          ),
                        ),
                        DataCell(Text('${item['saldoAtual'] ?? 0}')),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        MovimentacoesPagination(
          page: _livroPage,
          pageSize: _livroPageSize,
          hasMore: _livroHasMore,
          isBusy: _loadingLivro,
          totalCount: _livroTotal,
          itemsOnPage: _livroItems.length,
          onPageChanged: (nextPage) {
            setState(() => _livroPage = nextPage);
            _loadLivro();
          },
          onPageSizeChanged: (value) {
            setState(() {
              _livroPageSize = value;
              _livroPage = 1;
            });
            _loadLivro();
          },
        ),
        Text(
          'Total: $_livroTotal movimento(s)',
          style: Theme.of(
            context,
          ).textTheme.erpCaption.copyWith(color: t.textMuted),
        ),
      ],
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title,
    required this.child,
    this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.erpCardTitle,
                ),
              ),
              IconButton(
                onPressed: onClose ?? () => AdaptiveNavigator.close(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.erpCaption.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final value = label ?? '—';
    final color = switch (value) {
      'UTILIZADA' || 'SAIDA' => t.brandGreen,
      'PENDENTE' || 'ENTRADA' => t.posInfo,
      'EXPIRADA' || 'CANCELAMENTO' => t.posDanger,
      _ => t.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.erpLabel.copyWith(color: color),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/async_type_ahead_field.dart';
import '../../domain/entities/estoque_item.dart';
import '../providers/estoque_provider.dart';
import '../../data/datasources/estoque_remote_datasource.dart';
import '../../../../stock/data/datasources/fornecedor_remote_datasource.dart';
import '../../../../stock/data/models/fornecedor_model.dart';
import '../../../../stock/presentation/providers/movimentacao_provider.dart';

import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';
import '../../../../../shared/widgets/inputs/formatters/date_input_formatter.dart';

abstract final class EstoqueStockEntryHelper {
  EstoqueStockEntryHelper._();

  static Future<void> entradaCompra(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
    List<({String id, String nome})> fornecedores,
  ) async {
    final width = AdaptiveNavigator.widthOf(context);
    final panelWidth = width >= AdaptiveSideSheetMetrics.desktopBreakpoint
        ? 520.0
        : 480.0;

    await AdaptiveNavigator.openPanel<void>(
      context: context,
      sideSheetWidth: panelWidth,
      routeSettings: const RouteSettings(name: '/estoque/entrada-compra'),
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return Scaffold(
            appBar: AppBar(title: Text('Entrada — ${item.produtoNomeComercial ?? 'Produto'}')),
            body: _EntradaCompraFormContent(
              item: item,
              fornecedores: fornecedores,
              showHeader: false,
            ),
          );
        }
        return _EntradaCompraFormContent(
          item: item,
          fornecedores: fornecedores,
          showHeader: true,
          onClose: () => AdaptiveNavigator.close(detailContext),
        );
      },
    );
  }

  static Future<void> novoLote(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final width = AdaptiveNavigator.widthOf(context);
    final panelWidth = width >= AdaptiveSideSheetMetrics.desktopBreakpoint
        ? 520.0
        : 480.0;

    await AdaptiveNavigator.openPanel<void>(
      context: context,
      sideSheetWidth: panelWidth,
      routeSettings: const RouteSettings(name: '/estoque/novo-lote'),
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Novo lote')),
            body: const _NovoLoteFormContent(showHeader: false),
          );
        }
        return _NovoLoteFormContent(
          showHeader: true,
          onClose: () => AdaptiveNavigator.close(detailContext),
        );
      },
    );
  }
}

class _EntradaCompraFormContent extends ConsumerStatefulWidget {
  const _EntradaCompraFormContent({
    required this.item,
    required this.fornecedores,
    this.showHeader = true,
    this.onClose,
  });

  final EstoqueItem item;
  final List<({String id, String nome})> fornecedores;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_EntradaCompraFormContent> createState() =>
      _EntradaCompraFormContentState();
}

class _EntradaCompraFormContentState extends ConsumerState<_EntradaCompraFormContent> {
  late final TextEditingController _quantidadeController;
  late final TextEditingController _compraController;
  late final TextEditingController _vendaController;
  late final TextEditingController _loteController;
  late final TextEditingController _validadeController;
  String? _fornecedorId;

  @override
  void initState() {
    super.initState();
    _quantidadeController = TextEditingController();
    _compraController =
        TextEditingController(text: widget.item.precoCompra.toString());
    _vendaController =
        TextEditingController(text: widget.item.precoVenda?.toString() ?? '');
    _loteController = TextEditingController(text: widget.item.numeroLote);
    _validadeController = TextEditingController(
      text: widget.item.dataValidade != null
          ? DateFormat('dd/MM/yyyy').format(widget.item.dataValidade!.toLocal())
          : '',
    );
    _fornecedorId = widget.item.fornecedorId;
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _compraController.dispose();
    _vendaController.dispose();
    _loteController.dispose();
    _validadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantidade =
        num.tryParse(_quantidadeController.text.replaceAll(',', '.'));
    final precoCompra =
        num.tryParse(_compraController.text.replaceAll(',', '.'));
    final precoVenda =
        num.tryParse(_vendaController.text.replaceAll(',', '.'));
    final numeroLote = _loteController.text.trim();
    final dataValidadeRaw = _validadeController.text.trim();
    final dataValidade = _normalizeDateForApi(dataValidadeRaw);

    if (_fornecedorId == null || _fornecedorId!.isEmpty) {
      PharmaFeedback.error(context, 'Selecione um fornecedor');
      return;
    }
    if (quantidade == null || quantidade <= 0) {
      PharmaFeedback.error(context, 'Quantidade inválida');
      return;
    }
    if (precoCompra == null || precoCompra < 0) {
      PharmaFeedback.error(context, 'Valor de compra inválido');
      return;
    }
    if (precoVenda == null || precoVenda <= 0) {
      PharmaFeedback.error(context, 'Valor de venda inválido');
      return;
    }
    if (numeroLote.isEmpty) {
      PharmaFeedback.error(context, 'Lote é obrigatório');
      return;
    }
    if (dataValidade == null) {
      PharmaFeedback.error(context, 'Informe a validade no formato DD/MM/AAAA');
      return;
    }

    final controller = ref.read(estoqueListProvider.notifier);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).entradaCompra(
            produtoId: widget.item.produtoId,
            fornecedorId: _fornecedorId!,
            numeroLote: numeroLote,
            dataValidade: dataValidade,
            quantidade: quantidade,
            precoCompra: precoCompra,
            precoVenda: precoVenda,
          );
      if (!mounted) return;
      controller.applyLoteStockDelta(
        loteId: widget.item.id,
        delta: quantidade,
      );
      PharmaFeedback.success(context, 'Entrada registada com sucesso');
      await controller.syncAfterMutation();
      ref.invalidate(movimentacaoListProvider);
      if (!mounted) return;
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        AdaptiveNavigator.close(context);
      }
    } on ApiFailure catch (e) {
      if (mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (mounted) PharmaFeedback.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Entrada — ${widget.item.produtoNomeComercial ?? 'Produto'}',
                    style: Theme.of(context).textTheme.erpCardTitle,
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('fornecedor-$_fornecedorId'),
                  initialValue: _fornecedorId,
                  decoration: const InputDecoration(
                    labelText: 'Fornecedor',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.fornecedores
                      .map(
                        (f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _fornecedorId = value),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _quantidadeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _compraController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Valor compra',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _vendaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Valor venda',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _loteController,
                  decoration: const InputDecoration(
                    labelText: 'Número lote',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _validadeController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DateInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Data validade',
                    hintText: 'DD/MM/AAAA',
                    counterText: '',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () => _selectDate(context, _validadeController),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showHeader) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onClose ?? () => AdaptiveNavigator.close(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NovoLoteFormContent extends ConsumerStatefulWidget {
  const _NovoLoteFormContent({
    this.showHeader = true,
    this.onClose,
  });

  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_NovoLoteFormContent> createState() => _NovoLoteFormContentState();
}

class _NovoLoteFormContentState extends ConsumerState<_NovoLoteFormContent> {
  final _produtoController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _compraController = TextEditingController();
  final _vendaController = TextEditingController();
  final _loteController = TextEditingController();
  final _validadeController = TextEditingController();

  String? _produtoId;
  String? _produtoLabel;
  String? _fornecedorId;
  String? _fornecedorLabel;

  @override
  void dispose() {
    _produtoController.dispose();
    _fornecedorController.dispose();
    _quantidadeController.dispose();
    _compraController.dispose();
    _vendaController.dispose();
    _loteController.dispose();
    _validadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantidade =
        num.tryParse(_quantidadeController.text.replaceAll(',', '.'));
    final precoCompra =
        num.tryParse(_compraController.text.replaceAll(',', '.'));
    final precoVenda =
        num.tryParse(_vendaController.text.replaceAll(',', '.'));
    final numeroLote = _loteController.text.trim();
    final dataValidadeRaw = _validadeController.text.trim();
    final dataValidade = _normalizeDateForApi(dataValidadeRaw);

    if (_produtoId == null || _produtoId!.isEmpty) {
      PharmaFeedback.error(context, 'Selecione um produto');
      return;
    }
    if (_fornecedorId == null || _fornecedorId!.isEmpty) {
      PharmaFeedback.error(context, 'Selecione um fornecedor');
      return;
    }
    if (quantidade == null || quantidade <= 0) {
      PharmaFeedback.error(context, 'Quantidade inválida');
      return;
    }
    if (precoCompra == null || precoCompra < 0) {
      PharmaFeedback.error(context, 'Preço de compra inválido');
      return;
    }
    if (precoVenda == null || precoVenda <= 0) {
      PharmaFeedback.error(context, 'Preço de venda inválido');
      return;
    }
    if (numeroLote.isEmpty) {
      PharmaFeedback.error(context, 'Lote é obrigatório');
      return;
    }
    if (dataValidade == null) {
      PharmaFeedback.error(context, 'Informe a validade no formato DD/MM/AAAA');
      return;
    }

    final controller = ref.read(estoqueListProvider.notifier);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).createLote(
            produtoId: _produtoId!,
            fornecedorId: _fornecedorId!,
            numeroLote: numeroLote,
            dataValidade: dataValidade,
            quantidadeInicial: quantidade,
            precoCompra: precoCompra,
            precoVenda: precoVenda,
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Lote criado com sucesso');
      await controller.syncAfterMutation();
      ref.invalidate(movimentacaoListProvider);
      if (!mounted) return;
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        AdaptiveNavigator.close(context);
      }
    } on ApiFailure catch (e) {
      if (mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (mounted) PharmaFeedback.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Novo lote',
                    style: Theme.of(context).textTheme.erpCardTitle,
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AsyncTypeAheadField<ProdutoSearchResult>(
                  controller: _produtoController,
                  labelText: 'Produto',
                  hintText: _produtoLabel ?? 'Nome comercial, dosagem ou forma…',
                  suggestionsCallback: (query) => ref
                      .read(estoqueRemoteDataSourceProvider)
                      .searchProdutos(query: query),
                  itemLabel: (produto) => produto.nomeComercial,
                  itemSubtitle: (produto) => produto.detalhesLabel,
                  onSelected: (produto) {
                    setState(() {
                      _produtoId = produto.id;
                      _produtoLabel = produto.displayLabel;
                      _produtoController.text = produto.displayLabel;
                    });
                  },
                ),
                SizedBox(height: s.sm),
                AsyncTypeAheadField<FornecedorDetalheModel>(
                  controller: _fornecedorController,
                  labelText: 'Fornecedor',
                  hintText: _fornecedorLabel ?? 'Digite para pesquisar…',
                  suggestionsCallback: (query) async {
                    final result = await ref
                        .read(fornecedorRemoteDataSourceProvider)
                        .search(query: query, pageSize: 10);
                    return result.items;
                  },
                  itemLabel: (fornecedor) => fornecedor.nome,
                  itemSubtitle: (fornecedor) {
                    final parts = <String>[
                      if (fornecedor.nuit != null &&
                          fornecedor.nuit!.trim().isNotEmpty)
                        'NUIT ${fornecedor.nuit}',
                      if (fornecedor.telefone != null &&
                          fornecedor.telefone!.trim().isNotEmpty)
                        fornecedor.telefone!.trim(),
                    ];
                    return parts.join(' · ');
                  },
                  onSelected: (fornecedor) {
                    setState(() {
                      _fornecedorId = fornecedor.id;
                      _fornecedorLabel = fornecedor.nome;
                      _fornecedorController.text = fornecedor.nome;
                    });
                  },
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _loteController,
                  decoration: const InputDecoration(
                    labelText: 'Número lote',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _quantidadeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade inicial',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _compraController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço compra',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _vendaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço venda',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: _validadeController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DateInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Data validade',
                    hintText: 'DD/MM/AAAA',
                    counterText: '',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () => _selectDate(context, _validadeController),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showHeader) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onClose ?? () => AdaptiveNavigator.close(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? _normalizeDateForApi(String rawValue) {
  final digits = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 8) return null;

  final formatted =
      '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4, 8)}';

  try {
    final parsed = DateFormat('dd/MM/yyyy').parseStrict(formatted);
    return DateFormat('yyyy-MM-dd').format(parsed);
  } catch (_) {
    return null;
  }
}

Future<void> _selectDate(
  BuildContext context,
  TextEditingController controller,
) async {
  FocusScope.of(context).unfocus();

  DateTime initialDate = DateTime.now();
  if (controller.text.length == 10) {
    try {
      initialDate = DateFormat('dd/MM/yyyy').parseStrict(controller.text);
    } catch (_) {}
  }

  final navigatorContext = Navigator.of(context, rootNavigator: false).context;
  final picked = await showDatePicker(
    context: navigatorContext,
    initialDate: initialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
    useRootNavigator: false,
  );

  if (picked != null) {
    controller.text = DateFormat('dd/MM/yyyy').format(picked);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/component_theme.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/async_type_ahead_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_date_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/estoque_item.dart';
import '../providers/estoque_provider.dart';
import '../../data/datasources/estoque_remote_datasource.dart';
import '../../../../stock/data/datasources/fornecedor_remote_datasource.dart';
import '../../../../stock/data/models/fornecedor_model.dart';
import '../../../../stock/presentation/providers/movimentacao_provider.dart';

/// ENTRADA = estoque inicial; COMPRA = mercadoria de fornecedor.
enum _LoteEntryModo { entrada, compra }

/// Compra a fornecedor ou transferência entre filiais.
enum _MovimentarModo { compra, transferencia }

abstract final class EstoqueStockEntryHelper {
  EstoqueStockEntryHelper._();

  /// Movimentar stock sobre produto/lote existente (compra ou transferência).
  static Future<void> movimentarStock(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
    List<({String id, String nome})> fornecedores,
  ) async {
    await AdaptiveNavigator.openPanel<void>(
      context: context,
      routeSettings: const RouteSettings(name: '/estoque/movimentar-stock'),
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Movimentar Stock — ${item.produtoNomeComercial ?? 'Produto'}',
              ),
            ),
            body: _MovimentarStockFormContent(
              item: item,
              fornecedores: fornecedores,
              showHeader: false,
            ),
          );
        }
        return _MovimentarStockFormContent(
          item: item,
          fornecedores: fornecedores,
          showHeader: true,
          onClose: () => AdaptiveNavigator.close(detailContext),
        );
      },
    );
  }

  /// @deprecated Use [movimentarStock].
  static Future<void> entradaCompra(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
    List<({String id, String nome})> fornecedores,
  ) =>
      movimentarStock(context, ref, item, fornecedores);

  static Future<void> novoLote(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await AdaptiveNavigator.openPanel<void>(
      context: context,
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

class _MovimentarStockFormContent extends ConsumerStatefulWidget {
  const _MovimentarStockFormContent({
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
  ConsumerState<_MovimentarStockFormContent> createState() => _MovimentarStockFormContentState();
}

class _MovimentarStockFormContentState extends ConsumerState<_MovimentarStockFormContent> {
  late final TextEditingController _quantidadeController;
  late final TextEditingController _compraController;
  late final TextEditingController _vendaController;
  late final TextEditingController _loteController;
  late final TextEditingController _validadeController;
  late final TextEditingController _documentoController;
  _MovimentarModo _modo = _MovimentarModo.compra;
  String? _fornecedorId;
  String? _destinoBranchId;

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
    _documentoController = TextEditingController();
    _fornecedorId = widget.item.fornecedorId;
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _compraController.dispose();
    _vendaController.dispose();
    _loteController.dispose();
    _validadeController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantidade =
        num.tryParse(_quantidadeController.text.replaceAll(',', '.'));
    final documento = _documentoController.text.trim();

    if (documento.isEmpty) {
      PharmaFeedback.error(
        context,
        'Documento de referência é obrigatório',
      );
      return;
    }
    if (documento.length > 100) {
      PharmaFeedback.error(
        context,
        'Documento de referência não pode exceder 100 caracteres',
      );
      return;
    }
    if (quantidade == null || quantidade <= 0) {
      PharmaFeedback.error(context, 'Quantidade inválida');
      return;
    }

    final controller = ref.read(estoqueListProvider.notifier);
    try {
      if (_modo == _MovimentarModo.transferencia) {
        if (_destinoBranchId == null || _destinoBranchId!.isEmpty) {
          PharmaFeedback.error(context, 'Selecione a filial de destino');
          return;
        }
        await ref.read(estoqueRemoteDataSourceProvider).transferirStock(
              produtoId: widget.item.produtoId,
              loteId: widget.item.id,
              destinoBranchId: _destinoBranchId!,
              documentoReferencia: documento,
              quantidade: quantidade,
            );
        if (!mounted) return;
        controller.applyLoteStockDelta(
          loteId: widget.item.id,
          delta: -quantidade,
        );
        PharmaFeedback.success(context, 'Transferência registada com sucesso');
      } else {
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
          PharmaFeedback.error(
            context,
            'Informe a validade no formato DD/MM/AAAA',
          );
          return;
        }

        await ref.read(estoqueRemoteDataSourceProvider).entradaCompra(
              produtoId: widget.item.produtoId,
              fornecedorId: _fornecedorId!,
              documentoReferencia: documento,
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
        PharmaFeedback.success(context, 'Compra registada com sucesso');
      }

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
    final session = ref.watch(authSessionProvider).session;
    final currentBranchId = session?.branchId;
    final siblingBranches = session?.selectedTenant?.branches
            .where((b) => b.id != currentBranchId)
            .toList() ??
        const [];
    final isTransfer = _modo == _MovimentarModo.transferencia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(s.md, s.md, s.sm, s.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Movimentar Stock — ${widget.item.produtoNomeComercial ?? 'Produto'}',
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
            padding: EdgeInsets.all(s.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EnterpriseSelectFormField<_MovimentarModo>(
                  label: 'Tipo de movimento',
                  initialValue: _modo,
                  options: const [
                    EnterpriseSelectOption(
                      value: _MovimentarModo.compra,
                      label: 'Compra (fornecedor)',
                    ),
                    EnterpriseSelectOption(
                      value: _MovimentarModo.transferencia,
                      label: 'Transferência entre filiais',
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _modo = value);
                  },
                ),
                SizedBox(height: s.sm),
                EnterpriseTextField(
                  controller: _documentoController,
                  labelText: 'Documento de referência',
                  hintText: isTransfer
                      ? 'Guia de transferência'
                      : 'Factura, guia ou nota de entrega',
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(100),
                  ],
                ),
                SizedBox(height: s.sm),
                EnterpriseTextField(
                  controller: _quantidadeController,
                  labelText: 'Quantidade',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: s.sm),
                if (isTransfer) ...[
                  if (siblingBranches.isEmpty)
                    Text(
                      'Não há outras filiais activas neste tenant para transferir.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    EnterpriseSelectFormField<String>(
                      key: ValueKey('destino-$_destinoBranchId'),
                      label: 'Filial de destino',
                      initialValue: _destinoBranchId,
                      options: [
                        for (final branch in siblingBranches)
                          EnterpriseSelectOption<String>(
                            value: branch.id,
                            label: '${branch.name} (${branch.code})',
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _destinoBranchId = value),
                    ),
                ] else ...[
                  EnterpriseSelectFormField<String>(
                    key: ValueKey('fornecedor-$_fornecedorId'),
                    label: 'Fornecedor',
                    initialValue: _fornecedorId,
                    options: [
                      for (final fornecedor in widget.fornecedores)
                        EnterpriseSelectOption<String>(
                          value: fornecedor.id,
                          label: fornecedor.nome,
                        ),
                    ],
                    onChanged: (value) => setState(() => _fornecedorId = value),
                  ),
                  SizedBox(height: s.sm),
                  EnterpriseTextField(
                    controller: _compraController,
                    labelText: 'Valor compra',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                  ),
                  SizedBox(height: s.sm),
                  EnterpriseTextField(
                    controller: _vendaController,
                    labelText: 'Valor venda',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                  ),
                  SizedBox(height: s.sm),
                  EnterpriseTextField(
                    controller: _loteController,
                    labelText: 'Número lote',
                  ),
                  SizedBox(height: s.sm),
                  EnterpriseDateField(
                    labelText: 'Data validade',
                    controller: _validadeController,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.showHeader) const Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(s.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    widget.onClose ?? () => AdaptiveNavigator.close(context),
                child: const Text('Cancelar'),
              ),
              SizedBox(width: s.sm),
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
  ConsumerState<_NovoLoteFormContent> createState() =>
      _NovoLoteFormContentState();
}

class _NovoLoteFormContentState extends ConsumerState<_NovoLoteFormContent> {
  final _produtoController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _documentoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _compraController = TextEditingController();
  final _vendaController = TextEditingController();
  final _loteController = TextEditingController();
  final _validadeController = TextEditingController();

  _LoteEntryModo _modo = _LoteEntryModo.entrada;
  String? _produtoId;
  String? _produtoLabel;
  String? _fornecedorId;
  String? _fornecedorLabel;

  @override
  void dispose() {
    _produtoController.dispose();
    _fornecedorController.dispose();
    _documentoController.dispose();
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
    final documento = _documentoController.text.trim();
    final dataValidadeRaw = _validadeController.text.trim();
    final dataValidade = _normalizeDateForApi(dataValidadeRaw);
    final isCompra = _modo == _LoteEntryModo.compra;

    if (_produtoId == null || _produtoId!.isEmpty) {
      PharmaFeedback.error(context, 'Selecione um produto');
      return;
    }
    if (isCompra && (_fornecedorId == null || _fornecedorId!.isEmpty)) {
      PharmaFeedback.error(context, 'Selecione um fornecedor');
      return;
    }
    if (isCompra && documento.isEmpty) {
      PharmaFeedback.error(
        context,
        'Documento de referência é obrigatório para compra',
      );
      return;
    }
    if (documento.length > 100) {
      PharmaFeedback.error(
        context,
        'Documento de referência não pode exceder 100 caracteres',
      );
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
            modo: isCompra ? 'COMPRA' : 'ENTRADA',
            fornecedorId: _fornecedorId,
            documentoReferencia: documento.isEmpty ? null : documento,
            numeroLote: numeroLote,
            dataValidade: dataValidade,
            quantidadeInicial: quantidade,
            precoCompra: precoCompra,
            precoVenda: precoVenda,
          );
      if (!mounted) return;
      PharmaFeedback.success(
        context,
        isCompra
            ? 'Lote de compra registado com sucesso'
            : 'Entrada de estoque inicial registada com sucesso',
      );
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
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final outlinedStyle = PharmaComponentTheme.outlined(t, scheme);
    final isCompra = _modo == _LoteEntryModo.compra;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(s.md, s.md, s.sm, s.sm),
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
            padding: EdgeInsets.all(s.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EnterpriseSelectFormField<_LoteEntryModo>(
                  label: 'Tipo de entrada',
                  initialValue: _modo,
                  options: const [
                    EnterpriseSelectOption(
                      value: _LoteEntryModo.entrada,
                      label: 'Entrada (estoque inicial)',
                    ),
                    EnterpriseSelectOption(
                      value: _LoteEntryModo.compra,
                      label: 'Compra (fornecedor)',
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _modo = value);
                  },
                ),
                SizedBox(height: s.sm),
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
                if (isCompra) ...[
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
                  EnterpriseTextField(
                    controller: _documentoController,
                    labelText: 'Documento de referência',
                    hintText: 'Factura, guia ou nota de entrega',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                  ),
                  SizedBox(height: s.sm),
                ] else ...[
                  AsyncTypeAheadField<FornecedorDetalheModel>(
                    controller: _fornecedorController,
                    labelText: 'Fornecedor (opcional)',
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
                  EnterpriseTextField(
                    controller: _documentoController,
                    labelText: 'Documento de referência (opcional)',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                  ),
                  SizedBox(height: s.sm),
                ],
                EnterpriseTextField(
                  controller: _loteController,
                  labelText: 'Número lote',
                ),
                SizedBox(height: s.sm),
                EnterpriseTextField(
                  controller: _quantidadeController,
                  labelText: 'Quantidade inicial',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                SizedBox(height: s.sm),
                EnterpriseTextField(
                  controller: _compraController,
                  labelText: 'Preço compra',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                SizedBox(height: s.sm),
                EnterpriseTextField(
                  controller: _vendaController,
                  labelText: 'Preço venda',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                SizedBox(height: s.sm),
                EnterpriseDateField(
                  labelText: 'Data validade',
                  controller: _validadeController,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                ),
              ],
            ),
          ),
        ),
        if (widget.showHeader) const Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(s.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cancel = OutlinedButton(
                style: outlinedStyle,
                onPressed:
                    widget.onClose ?? () => AdaptiveNavigator.close(context),
                child: const Text('Cancelar'),
              );
              final confirm = FilledButton(
                onPressed: _submit,
                child: const Text('Confirmar'),
              );
              if (constraints.maxWidth < Breakpoints.tablet) {
                return Row(
                  children: [
                    Expanded(child: cancel),
                    SizedBox(width: s.sm),
                    Expanded(child: confirm),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  cancel,
                  SizedBox(width: s.sm),
                  confirm,
                ],
              );
            },
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

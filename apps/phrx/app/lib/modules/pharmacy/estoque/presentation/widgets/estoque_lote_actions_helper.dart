import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/enterprise_date_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../data/datasources/estoque_remote_datasource.dart';
import '../../domain/entities/estoque_item.dart';
import '../providers/estoque_provider.dart';
import '../../../../stock/presentation/providers/movimentacao_provider.dart';

abstract final class EstoqueLoteActionsHelper {
  EstoqueLoteActionsHelper._();

  static Future<void> editarLote(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    await _openLoteActionPanel(
      context: context,
      routeName: '/estoque/lotes/${item.id}/editar',
      title: 'Editar lote',
      builder: (detailContext, showHeader, onClose) => _EditarLoteFormContent(
        item: item,
        showHeader: showHeader,
        onClose: onClose,
      ),
    );
  }

  static Future<void> alterarPreco(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    await _openLoteActionPanel(
      context: context,
      routeName: '/estoque/lotes/${item.id}/preco',
      title: 'Alterar preço do lote',
      builder: (detailContext, showHeader, onClose) => _AlterarPrecoFormContent(
        item: item,
        showHeader: showHeader,
        onClose: onClose,
      ),
    );
  }

  static Future<void> ajustarStock(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    await _openLoteActionPanel(
      context: context,
      routeName: '/estoque/lotes/${item.id}/ajustar-stock',
      title: 'Ajustar stock',
      builder: (detailContext, showHeader, onClose) => _AjustarStockFormContent(
        item: item,
        showHeader: showHeader,
        onClose: onClose,
      ),
    );
  }

  static Future<void> movimentacaoSanitaria(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    await _openLoteActionPanel(
      context: context,
      routeName: '/estoque/lotes/${item.id}/movimentacao-sanitaria',
      title: 'Movimentação sanitária',
      builder: (detailContext, showHeader, onClose) =>
          _MovimentacaoSanitariaFormContent(
        item: item,
        showHeader: showHeader,
        onClose: onClose,
      ),
    );
  }
}

Future<void> _openLoteActionPanel({
  required BuildContext context,
  required String routeName,
  required String title,
  required Widget Function(
    BuildContext detailContext,
    bool showHeader,
    VoidCallback? onClose,
  ) builder,
}) async {
  await AdaptiveNavigator.openPanel<void>(
    context: context,
    routeSettings: RouteSettings(name: routeName),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: builder(detailContext, false, null),
        );
      }
      return builder(
        detailContext,
        true,
        () => AdaptiveNavigator.close(detailContext),
      );
    },
  );
}

class _EstoqueActionFormShell extends StatelessWidget {
  const _EstoqueActionFormShell({
    required this.title,
    required this.showHeader,
    this.onClose,
    required this.form,
    required this.submitLabel,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final String title;
  final bool showHeader;
  final VoidCallback? onClose;
  final Widget form;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
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
                    title,
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: form,
          ),
        ),
        if (showHeader) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : (onClose ?? () => AdaptiveNavigator.close(context)),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(submitLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditarLoteFormContent extends ConsumerStatefulWidget {
  const _EditarLoteFormContent({
    required this.item,
    required this.showHeader,
    this.onClose,
  });

  final EstoqueItem item;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_EditarLoteFormContent> createState() =>
      _EditarLoteFormContentState();
}

class _EditarLoteFormContentState extends ConsumerState<_EditarLoteFormContent> {
  late final TextEditingController _numeroController;
  late final TextEditingController _validadeController;
  late final TextEditingController _fabricacaoController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(text: widget.item.numeroLote);
    _validadeController = TextEditingController(
      text: widget.item.dataValidade != null
          ? DateFormat('dd/MM/yyyy').format(widget.item.dataValidade!.toLocal())
          : '',
    );
    _fabricacaoController = TextEditingController();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _validadeController.dispose();
    _fabricacaoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final numeroLote = _numeroController.text.trim();
    final dataValidadeRaw = _validadeController.text.trim();
    final dataFabricacaoRaw = _fabricacaoController.text.trim();

    final dataValidade = _normalizeDateForApi(dataValidadeRaw);
    final dataFabricacao = dataFabricacaoRaw.isEmpty
        ? null
        : _normalizeDateForApi(dataFabricacaoRaw);

    if (dataValidade == null) {
      PharmaFeedback.error(context, 'Informe a validade no formato DD/MM/AAAA');
      return;
    }

    if (dataFabricacaoRaw.isNotEmpty && dataFabricacao == null) {
      PharmaFeedback.error(context, 'Informe a fabricação no formato DD/MM/AAAA');
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(widget.item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).updateLote(
            widget.item.id,
            numeroLote: numeroLote,
            dataValidade: dataValidade,
            dataFabricacao: dataFabricacao,
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Lote actualizado com sucesso');
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
    } finally {
      controller.setActionLoteId(null);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return _EstoqueActionFormShell(
      title: 'Editar lote',
      showHeader: widget.showHeader,
      onClose: widget.onClose,
      submitLabel: 'Guardar',
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseTextField(
            controller: _numeroController,
            labelText: 'Número do lote',
          ),
          SizedBox(height: s.sm),
          EnterpriseDateField(
            labelText: 'Data de validade',
            controller: _validadeController,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
          SizedBox(height: s.sm),
          EnterpriseDateField(
            labelText: 'Data de fabricação (opcional)',
            controller: _fabricacaoController,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ],
      ),
    );
  }
}

class _AlterarPrecoFormContent extends ConsumerStatefulWidget {
  const _AlterarPrecoFormContent({
    required this.item,
    required this.showHeader,
    this.onClose,
  });

  final EstoqueItem item;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_AlterarPrecoFormContent> createState() =>
      _AlterarPrecoFormContentState();
}

class _AlterarPrecoFormContentState extends ConsumerState<_AlterarPrecoFormContent> {
  late final TextEditingController _compraController;
  late final TextEditingController _vendaController;
  late final TextEditingController _motivoController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _compraController =
        TextEditingController(text: widget.item.precoCompra.toString());
    _vendaController = TextEditingController(
      text: widget.item.precoVenda?.toString() ?? '',
    );
    _motivoController = TextEditingController();
  }

  @override
  void dispose() {
    _compraController.dispose();
    _vendaController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final precoCompra =
        num.tryParse(_compraController.text.replaceAll(',', '.')) ??
            widget.item.precoCompra;
    final precoVendaRaw = _vendaController.text.trim();
    final precoVenda = precoVendaRaw.isEmpty
        ? null
        : num.tryParse(precoVendaRaw.replaceAll(',', '.'));
    final motivo = _motivoController.text.trim();

    setState(() => _isSubmitting = true);
    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(widget.item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).updateLotePrecos(
            widget.item.id,
            precoCompra: precoCompra,
            precoVenda: precoVenda,
            motivo: motivo.isEmpty ? null : motivo,
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Preços actualizados com sucesso');
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
    } finally {
      controller.setActionLoteId(null);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return _EstoqueActionFormShell(
      title: 'Alterar preço do lote',
      showHeader: widget.showHeader,
      onClose: widget.onClose,
      submitLabel: 'Confirmar',
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseTextField(
            controller: _compraController,
            labelText: 'Preço de compra',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          SizedBox(height: s.sm),
          EnterpriseTextField(
            controller: _vendaController,
            labelText: 'Preço de venda',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          SizedBox(height: s.sm),
          EnterpriseTextField(
            controller: _motivoController,
            labelText: 'Motivo da alteração',
            hintText: 'Opcional',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _AjustarStockFormContent extends ConsumerStatefulWidget {
  const _AjustarStockFormContent({
    required this.item,
    required this.showHeader,
    this.onClose,
  });

  final EstoqueItem item;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_AjustarStockFormContent> createState() =>
      _AjustarStockFormContentState();
}

class _AjustarStockFormContentState extends ConsumerState<_AjustarStockFormContent> {
  late final TextEditingController _quantidadeController;
  late final TextEditingController _motivoController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantidadeController = TextEditingController();
    _motivoController = TextEditingController();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantidade =
        num.tryParse(_quantidadeController.text.replaceAll(',', '.'));
    final motivo = _motivoController.text.trim();

    if (quantidade == null || quantidade == 0) {
      PharmaFeedback.error(context, 'Indique uma quantidade válida');
      return;
    }
    if (motivo.isEmpty) {
      PharmaFeedback.error(context, 'Motivo é obrigatório');
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(widget.item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).adjustStock(
            produtoId: widget.item.produtoId,
            loteId: widget.item.id,
            quantidade: quantidade,
            motivo: motivo,
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Stock ajustado com sucesso');
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
    } finally {
      controller.setActionLoteId(null);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return _EstoqueActionFormShell(
      title: 'Ajustar stock',
      showHeader: widget.showHeader,
      onClose: widget.onClose,
      submitLabel: 'Confirmar',
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Stock actual: ${LoteStockUtils.formatDisponivelFromNum(widget.item.quantidadeDisponivel)}',
            style: Theme.of(context).textTheme.erpBodySecondary,
          ),
          SizedBox(height: s.sm),
          EnterpriseTextField(
            controller: _quantidadeController,
            labelText: 'Quantidade (+ entrada / − saída)',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
          SizedBox(height: s.sm),
          EnterpriseTextField(
            controller: _motivoController,
            labelText: 'Motivo',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _MovimentacaoSanitariaFormContent extends ConsumerStatefulWidget {
  const _MovimentacaoSanitariaFormContent({
    required this.item,
    required this.showHeader,
    this.onClose,
  });

  final EstoqueItem item;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_MovimentacaoSanitariaFormContent> createState() =>
      _MovimentacaoSanitariaFormContentState();
}

class _MovimentacaoSanitariaFormContentState
    extends ConsumerState<_MovimentacaoSanitariaFormContent> {
  static const _tipoLabels = <String, String>{
    'QUARENTENA': 'Quarentena',
    'LIBERACAO': 'Liberação',
    'INCINERACAO': 'Incineração',
    'RECALL': 'Recall',
    'DEVOLUCAO_FORNECEDOR': 'Devolução ao fornecedor',
  };

  late String _tipo;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _motivoController;
  late final TextEditingController _documentoController;
  bool _isSubmitting = false;

  List<String> get _acoesPermitidas => widget.item.acoesPermitidas;

  @override
  void initState() {
    super.initState();
    _tipo = _acoesPermitidas.isNotEmpty ? _acoesPermitidas.first : 'QUARENTENA';
    _quantidadeController = TextEditingController();
    _motivoController = TextEditingController();
    _documentoController = TextEditingController();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _motivoController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_acoesPermitidas.isEmpty) {
      PharmaFeedback.error(
        context,
        'Não existem movimentações sanitárias permitidas para este lote.',
      );
      return;
    }
    if (!_acoesPermitidas.contains(_tipo)) {
      PharmaFeedback.error(
        context,
        'A acção seleccionada não é permitida no estado sanitário actual.',
      );
      return;
    }

    final motivo = _motivoController.text.trim();
    final documento = _documentoController.text.trim();
    final quantidade =
        num.tryParse(_quantidadeController.text.replaceAll(',', '.'));

    if (motivo.length < 3) {
      PharmaFeedback.error(context, 'Motivo é obrigatório');
      return;
    }
    if (_tipo != 'RECALL' && (quantidade == null || quantidade <= 0)) {
      PharmaFeedback.error(context, 'Quantidade inválida');
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(widget.item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).movimentacaoSanitaria(
            widget.item.id,
            tipo: _tipo,
            motivo: motivo,
            quantidade: _tipo == 'RECALL' ? null : quantidade,
            documentoReferencia: documento.isEmpty ? null : documento,
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Movimentação sanitária registada');
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
    } finally {
      controller.setActionLoteId(null);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final requiresQty = _tipo != 'RECALL';
    final estado =
        widget.item.estadoSanitarioEfetivo ?? widget.item.estadoSanitario ?? '—';

    return _EstoqueActionFormShell(
      title: 'Movimentação sanitária',
      showHeader: widget.showHeader,
      onClose: widget.onClose,
      submitLabel: 'Confirmar',
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estado sanitário: $estado',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: s.sm),
          if (_acoesPermitidas.isEmpty)
            Text(
              'Nenhuma movimentação permitida neste estado (ex.: lote incinerado).',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            EnterpriseSelectFormField<String>(
              key: ValueKey('sanitaria-tipo-$_tipo'),
              label: 'Tipo de movimentação',
              initialValue:
                  _acoesPermitidas.contains(_tipo) ? _tipo : _acoesPermitidas.first,
              options: [
                for (final value in _acoesPermitidas)
                  EnterpriseSelectOption<String>(
                    value: value,
                    label: _tipoLabels[value] ?? value,
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _tipo = value);
              },
            ),
          if (requiresQty && _acoesPermitidas.isNotEmpty) ...[
            SizedBox(height: s.sm),
            EnterpriseTextField(
              controller: _quantidadeController,
              labelText: 'Quantidade',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          if (_acoesPermitidas.isNotEmpty) ...[
            SizedBox(height: s.sm),
            EnterpriseTextField(
              controller: _motivoController,
              labelText: 'Motivo',
              maxLines: 2,
            ),
            SizedBox(height: s.sm),
            EnterpriseTextField(
              controller: _documentoController,
              labelText: 'Documento de referência',
              hintText: 'Opcional',
            ),
          ],
        ],
      ),
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

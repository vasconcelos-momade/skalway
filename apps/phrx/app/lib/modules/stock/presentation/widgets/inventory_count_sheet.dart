import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../../shared/widgets/dialogs/enterprise_overlay_tokens.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/async_type_ahead_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../pharmacy/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../domain/entities/inventario.dart';
import '../providers/inventario_provider.dart';

String formatInventoryQuantity(num value) {
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String formatInventoryDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value);
}

class NovoInventarioDialogResult {
  const NovoInventarioDialogResult({this.observacao});

  final String? observacao;
}

Future<NovoInventarioDialogResult?> showNovoInventarioDialog(
  BuildContext context,
) {
  return AdaptiveNavigator.openEmbeddedForm<NovoInventarioDialogResult>(
    context: context,
    title: const Text('Iniciar Inventário'),
    size: EnterpriseOverlaySize.small,
    formBuilder: (formContext, {required bool embedded}) {
      return _NovoInventarioForm(embedded: embedded);
    },
  );
}

class _NovoInventarioForm extends StatefulWidget {
  const _NovoInventarioForm({required this.embedded});

  final bool embedded;

  @override
  State<_NovoInventarioForm> createState() => _NovoInventarioFormState();
}

class _NovoInventarioFormState extends State<_NovoInventarioForm> {
  final _observacao = TextEditingController();
  final _hoje = DateTime.now();

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = t.density;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EnterpriseTextFormField(
          initialValue: formatInventoryDate(_hoje),
          readOnly: true,
          labelText: 'Data',
          helperText: 'Preenchida automaticamente',
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          controller: _observacao,
          labelText: 'Observação',
          hintText: 'Opcional',
          maxLines: 3,
        ),
        SizedBox(height: s.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => AdaptiveNavigator.close(context),
                child: const Text('Cancelar'),
              ),
            ),
            SizedBox(width: s.sm),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  AdaptiveNavigator.close(
                    context,
                    NovoInventarioDialogResult(
                      observacao: _observacao.text.trim().isEmpty
                          ? null
                          : _observacao.text.trim(),
                    ),
                  );
                },
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> showInventariarProdutoSheet(
  BuildContext context, {
  required WidgetRef ref,
  required InventarioProdutoApto produto,
}) {
  return AdaptiveNavigator.openPanel<void>(
    context: context,
    routeSettings: RouteSettings(name: '/inventario/produto/${produto.id}'),
    builder: (sheetContext) {
      final form = _InventariarProdutoForm(produto: produto);
      if (AdaptiveNavigator.isMobile(sheetContext)) {
        return Scaffold(
          appBar: AppBar(title: const Text('Inventariar Produto')),
          body: SafeArea(child: form),
        );
      }
      return form;
    },
  );
}

class _InventariarProdutoForm extends ConsumerStatefulWidget {
  const _InventariarProdutoForm({required this.produto});

  final InventarioProdutoApto produto;

  @override
  ConsumerState<_InventariarProdutoForm> createState() =>
      _InventariarProdutoFormState();
}

class _InventariarProdutoFormState
    extends ConsumerState<_InventariarProdutoForm> {
  final _loteSearch = TextEditingController();
  final _contado = TextEditingController();
  final _observacao = TextEditingController();
  Map<String, dynamic>? _selectedLote;
  bool _saving = false;

  @override
  void dispose() {
    _loteSearch.dispose();
    _contado.dispose();
    _observacao.dispose();
    super.dispose();
  }

  double get _stockSistema {
    final raw = _selectedLote?['quantidadeTotal'] ??
        _selectedLote?['quantidadeDisponivel'] ??
        _selectedLote?['quantidadeAtual'] ??
        _selectedLote?['stockBalance']?['quantidadeTotal'] ??
        0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }

  double? get _contadoValue =>
      double.tryParse(_contado.text.replaceAll(',', '.'));

  double? get _diferenca {
    final contado = _contadoValue;
    if (contado == null || _selectedLote == null) return null;
    return contado - _stockSistema;
  }

  Future<List<Map<String, dynamic>>> _searchLotes(String query) async {
    final response =
        await ref.read(inventoryRemoteDataSourceProvider).searchLotes(
              query: query,
              produtoId: widget.produto.id,
              estadoSanitario: 'VALIDO',
              page: 1,
              pageSize: 20,
            );
    return response.items;
  }

  String _loteLabel(Map<String, dynamic> lote) {
    final numero = lote['numeroLote']?.toString() ?? '—';
    final validade = lote['dataValidade']?.toString();
    final stock = lote['quantidadeTotal'] ??
        lote['quantidadeDisponivel'] ??
        lote['quantidadeAtual'] ??
        lote['stockBalance']?['quantidadeTotal'] ??
        0;
    final validadeLabel = validade == null || validade.isEmpty
        ? '—'
        : formatInventoryDate(DateTime.tryParse(validade) ?? DateTime.now());
    return '$numero · Val. $validadeLabel · Stock ${formatInventoryQuantity(stock is num ? stock : 0)}';
  }

  Future<void> _submit() async {
    final lote = _selectedLote;
    final contado = _contadoValue;
    if (lote == null) {
      PharmaFeedback.error(context, 'Seleccione um lote.');
      return;
    }
    if (contado == null) {
      PharmaFeedback.error(context, 'Informe as unidades contadas.');
      return;
    }

    setState(() => _saving = true);
    await ref.read(inventarioProvider.notifier).addItem(
          produtoId: widget.produto.id,
          loteId: lote['id'].toString(),
          estoqueContado: contado,
          observacao: _observacao.text.trim().isEmpty
              ? null
              : _observacao.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);

    final error = ref.read(inventarioProvider).errorMessage;
    if (error == null) {
      AdaptiveNavigator.close(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final diferenca = _diferenca;
    final isMobile = AdaptiveNavigator.isMobile(context);

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AsyncTypeAheadField<Map<String, dynamic>>(
          labelText: 'Lote',
          hintText: 'Número do lote, validade ou stock...',
          controller: _loteSearch,
          minSearchLength: 0,
          suggestionsCallback: _searchLotes,
          itemLabel: _loteLabel,
          onSelected: (lote) {
            setState(() {
              _selectedLote = lote;
              _loteSearch.text = lote['numeroLote']?.toString() ?? '';
              _contado.text = formatInventoryQuantity(_stockSistema);
            });
          },
        ),
        SizedBox(height: s.lg),
        EnterpriseTextFormField(
          initialValue: widget.produto.nomeComercial,
          readOnly: true,
          labelText: 'Produto',
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          key: ValueKey('lote-${_selectedLote?['id']}'),
          initialValue: _selectedLote?['numeroLote']?.toString() ?? '',
          readOnly: true,
          labelText: 'Lote',
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          key: ValueKey('val-${_selectedLote?['id']}'),
          initialValue: () {
            final raw = _selectedLote?['dataValidade']?.toString();
            if (raw == null) return '';
            final date = DateTime.tryParse(raw);
            return date == null ? raw : formatInventoryDate(date);
          }(),
          readOnly: true,
          labelText: 'Validade',
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          key: ValueKey('sys-${_selectedLote?['id']}'),
          initialValue: _selectedLote == null
              ? ''
              : formatInventoryQuantity(_stockSistema),
          readOnly: true,
          labelText: 'Stock Sistema',
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          controller: _contado,
          labelText: 'Unidades Contadas',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          key: ValueKey('diff-$diferenca'),
          initialValue:
              diferenca == null ? '' : formatInventoryQuantity(diferenca),
          readOnly: true,
          labelText: 'Diferença',
          helperText: diferenca == null
              ? null
              : (diferenca == 0 ? 'OK' : 'Divergência detectada'),
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          controller: _observacao,
          labelText: 'Observação',
          hintText: 'Opcional',
          maxLines: 3,
        ),
      ],
    );

    final actions = [
      EnterpriseOverlayActions.secondary(
        label: 'Cancelar',
        onPressed: _saving ? null : () => AdaptiveNavigator.close(context),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _submit,
        icon: _saving
            ? const PharmaButtonLoader()
            : const Icon(Icons.inventory_2_outlined),
        label: const Text('Adicionar ao Inventário'),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(s.lg),
              child: fields,
            ),
          ),
          EnterpriseOverlayFooter(
            actions: actions,
            expandOnNarrow: true,
          ),
        ],
      );
    }

    return EnterpriseFormSideSheet(
      title: const Text('Inventariar Produto'),
      onClose: () => AdaptiveNavigator.close(context),
      body: fields,
      actions: actions,
    );
  }
}

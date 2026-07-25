import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_metrics.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/pharma_surface.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';

import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_tax_rule.dart';
import '../../domain/produto_dispensacao.dart';
import '../providers/product_provider.dart';
import '../../../../../app/providers/auth_session_notifier.dart';

class ProdutoFormDialogResult {
  const ProdutoFormDialogResult({
    required this.nomeComercial,
    required this.categoriaId,
    required this.tipoDispensacao,
    required this.activo,
    this.barcode,
    this.nomeGenerico,
    this.dosagem,
    this.forma,
    this.apresentacao,
    this.estoqueMinimo,
    this.taxRuleId,
  });

  final String nomeComercial;
  final String categoriaId;
  final String tipoDispensacao;
  final bool activo;
  final String? barcode;
  final String? nomeGenerico;
  final String? dosagem;
  final String? forma;
  final String? apresentacao;
  final double? estoqueMinimo;
  final String? taxRuleId;

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'nomeComercial': nomeComercial,
      'categoriaId': categoriaId,
      'tipoDispensacao': tipoDispensacao,
      'ativo': activo,
      'activo': activo,
      'taxRuleId': taxRuleId,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      if (nomeGenerico != null && nomeGenerico!.isNotEmpty) 'nomeGenerico': nomeGenerico,
      if (dosagem != null && dosagem!.isNotEmpty) 'dosagem': dosagem,
      if (forma != null && forma!.isNotEmpty) 'forma': forma,
      if (apresentacao != null && apresentacao!.isNotEmpty) 'apresentacao': apresentacao,
      if (estoqueMinimo != null) 'estoqueMinimo': estoqueMinimo,
    };
  }
}

class ProdutoFormDialog extends ConsumerStatefulWidget {
  const ProdutoFormDialog({
    super.key,
    this.product,
    this.embedded = false,
    this.pinnedFooter = false,
  });

  final Product? product;
  final bool embedded;
  final bool pinnedFooter;

  bool get isEditing => product != null;

  @override
  ConsumerState<ProdutoFormDialog> createState() => _ProdutoFormDialogState();
}

class _ProdutoFormDialogState extends ConsumerState<ProdutoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _substanciaController;
  late final TextEditingController _dosagemController;
  late final TextEditingController _formaController;
  late final TextEditingController _apresentacaoController;
  late final TextEditingController _estoqueMinimoController;
  String? _categoriaId;
  late String _tipoDispensacao;
  late bool _activo;
  String? _selectedTaxRuleId;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nomeController = TextEditingController(text: product?.nomeComercial ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _substanciaController =
        TextEditingController(text: product?.nomeGenerico ?? '');
    _dosagemController = TextEditingController(text: product?.dosagem ?? '');
    _formaController = TextEditingController(text: product?.forma ?? '');
    _apresentacaoController =
        TextEditingController(text: product?.apresentacao ?? '');
    _estoqueMinimoController = TextEditingController(
      text: product != null ? product.estoqueMinimo.toString() : '0',
    );
    _categoriaId = product?.categoriaId;
    _tipoDispensacao = product?.tipoDispensacao ?? 'VENDA_LIVRE';
    _activo = product?.ativo ?? true;
    _selectedTaxRuleId = product?.taxRule?.id;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _barcodeController.dispose();
    _substanciaController.dispose();
    _dosagemController.dispose();
    _formaController.dispose();
    _apresentacaoController.dispose();
    _estoqueMinimoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final taxRules = ref.read(productTaxRulesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <ProductTaxRule>[],
        );
    final resolvedTaxRuleId = _resolveSelectedTaxRuleId(taxRules);
    final estoqueText = _estoqueMinimoController.text.trim().replaceAll(',', '.');
    final estoqueMinimo = double.tryParse(estoqueText);

    if (_categoriaId == null || _categoriaId!.isEmpty) {
      PharmaFeedback.error(context, 'Seleccione uma categoria');
      return;
    }

    if (estoqueMinimo == null || estoqueMinimo < 0) {
      PharmaFeedback.error(context, 'Informe um estoque mínimo válido');
      return;
    }

    AdaptiveNavigator.complete(
      context,
      ProdutoFormDialogResult(
        nomeComercial: _nomeController.text.trim(),
        categoriaId: _categoriaId!,
        tipoDispensacao: _tipoDispensacao,
        activo: _activo,
        barcode: _barcodeController.text.trim(),
        nomeGenerico: _substanciaController.text.trim(),
        dosagem: _dosagemController.text.trim(),
        forma: _formaController.text.trim(),
        apresentacao: _apresentacaoController.text.trim(),
        estoqueMinimo: estoqueMinimo,
        taxRuleId: resolvedTaxRuleId,
      ),
    );
  }

  String? _resolveSelectedTaxRuleId(List<ProductTaxRule> rules) {
    if (_selectedTaxRuleId != null &&
        rules.any((rule) => rule.id == _selectedTaxRuleId)) {
      return _selectedTaxRuleId;
    }

    final currentRule = widget.product?.taxRule;
    if (currentRule == null) {
      return _selectedTaxRuleId;
    }

    for (final rule in rules) {
      if (rule.id == null) {
        continue;
      }
      final sameId = currentRule.id != null && currentRule.id == rule.id;
      final sameCode =
          currentRule.codigo != null &&
          currentRule.codigo == rule.codigo;
      final sameSignature =
          currentRule.tipo == rule.tipo &&
          (currentRule.taxa - rule.taxa).abs() < 0.0001;
      if (sameId || sameCode || sameSignature) {
        return rule.id;
      }
    }

    return _selectedTaxRuleId;
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm, top: context.spacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.erpCardTitle,
      ),
    );
  }

  String _resolvedTipoDispensacao() {
    if (produtoTipoDispensacaoValues.contains(_tipoDispensacao)) {
      return _tipoDispensacao;
    }
    return produtoTipoDispensacaoValues.first;
  }

  String? _resolvedTaxRuleDropdownValue(List<ProductTaxRule> rules) {
    final candidate = _selectedTaxRuleId ?? widget.product?.taxRule?.id;
    if (candidate == null) {
      return null;
    }
    return rules.any((rule) => rule.id == candidate) ? candidate : null;
  }

  List<DropdownMenuItem<String?>> _taxRuleDropdownItems(List<ProductTaxRule> rules) {
    return [
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Sem regra fiscal'),
      ),
      ...rules
          .where((rule) => rule.id != null && rule.ativo)
          .map(
            (rule) => DropdownMenuItem<String?>(
              value: rule.id,
              child: Text(rule.displayLabel),
            ),
          ),
    ];
  }

  Widget _dropdownLoading(String label) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: const LinearProgressIndicator(),
    );
  }

  Widget _dropdownError(String label, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PharmaInstantDropdown<String?>(
          label: label,
          value: null,
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('—'),
            ),
          ],
          onChanged: null,
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          message,
          style: Theme.of(context).textTheme.erpBody.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final isMobileViewport = AdaptiveNavigator.isMobile(context);
    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );
    final taxRulesAsync = ref.watch(productTaxRulesProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final taxRules = taxRulesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <ProductTaxRule>[],
    );
    final tipoDispensacaoValue = _resolvedTipoDispensacao();
    final taxRuleDropdownValue = _resolvedTaxRuleDropdownValue(taxRules);
    final derivedSummary = produtoDispensacaoDerivedSummary(tipoDispensacaoValue);

    final formFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Informações gerais'),
        TextFormField(
          controller: _nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            return null;
          },
        ),
        SizedBox(height: s.md),
        if (!authReady || categoriesAsync.isLoading)
          _dropdownLoading('Categoria *')
        else if (categoriesAsync.hasError)
          _dropdownError(
            'Categoria *',
            'Não foi possível carregar categorias',
          )
        else ...[
          Builder(
            builder: (context) {
              final categories = categoriesAsync.requireValue;
              final resolvedId = _categoriaId != null &&
                      categories.any((c) => c.id == _categoriaId)
                  ? _categoriaId
                  : (categories.isNotEmpty ? categories.first.id : null);
              if (_categoriaId == null && resolvedId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _categoriaId = resolvedId);
                });
              }
              return PharmaInstantDropdown<String?>(
                label: 'Categoria *',
                value: resolvedId,
                items: categories
                    .map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.nome),
                      ),
                    )
                    .toList(growable: false),
                onChanged: categories.isEmpty
                    ? null
                    : (value) => setState(() => _categoriaId = value),
              );
            },
          ),
        ],
        SizedBox(height: s.md),
        TextFormField(
          controller: _substanciaController,
          decoration: const InputDecoration(
            labelText: 'Substância activa',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _dosagemController,
          decoration: const InputDecoration(
            labelText: 'Dosagem',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _formaController,
          decoration: const InputDecoration(
            labelText: 'Forma farmacêutica',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _apresentacaoController,
          decoration: const InputDecoration(
            labelText: 'Apresentação',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _barcodeController,
          decoration: const InputDecoration(
            labelText: 'Código de barras',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: s.lg),
        _sectionTitle(context, 'Comercial'),
        TextFormField(
          controller: _estoqueMinimoController,
          decoration: const InputDecoration(
            labelText: 'Estoque mínimo *',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final text = value?.trim().replaceAll(',', '.') ?? '';
            if (text.isEmpty) {
              return 'Estoque mínimo é obrigatório';
            }
            final parsed = double.tryParse(text);
            if (parsed == null || parsed < 0) {
              return 'Informe um valor válido';
            }
            return null;
          },
        ),
        SizedBox(height: s.md),
        if (!authReady || taxRulesAsync.isLoading)
          _dropdownLoading('Regra fiscal (IVA)')
        else if (taxRulesAsync.hasError)
          _dropdownError(
            'Regra fiscal (IVA)',
            'Não foi possível carregar as taxas de IVA.',
          )
        else
          PharmaInstantDropdown<String?>(
            label: 'Regra fiscal (IVA)',
            value: taxRuleDropdownValue,
            items: _taxRuleDropdownItems(taxRules),
            onChanged: (value) => setState(() => _selectedTaxRuleId = value),
          ),
        SizedBox(height: s.lg),
        _sectionTitle(context, 'Regulação'),
        PharmaInstantDropdown<String>(
          label: 'Tipo de dispensação *',
          value: tipoDispensacaoValue,
          items: produtoTipoDispensacaoValues
              .map(
                (tipo) => DropdownMenuItem<String>(
                  value: tipo,
                  child: Text(produtoTipoDispensacaoLabel(tipo)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _tipoDispensacao = value);
          },
        ),
        if (derivedSummary.isNotEmpty) ...[
          SizedBox(height: s.xs),
          Text(
            derivedSummary,
            style: Theme.of(context).textTheme.erpBodySecondary,
          ),
        ],
        SizedBox(height: s.lg),
        _sectionTitle(context, 'Estado'),
        SwitchListTile.adaptive(
          value: _activo,
          contentPadding: EdgeInsets.zero,
          title: const Text('Produto activo'),
          subtitle: const Text(
            'Produtos inactivos deixam de aparecer no catálogo operacional.',
          ),
          onChanged: (value) {
            setState(() => _activo = value);
          },
        ),
      ],
    );

    final actions = [
      OutlinedButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.isEditing ? 'Guardar' : 'Criar'),
      ),
    ];
    final actionsSection = PharmaResponsiveDialogActions(
      breakpoint: pharmaDialogBreakpointForWidth(MediaQuery.sizeOf(context).width),
      children: actions,
    );
    final pinnedBodyPadding = EdgeInsets.all(
      widget.embedded && !isMobileViewport ? 0 : s.lg,
    );

    final formBody = Form(
      key: _formKey,
      child: widget.pinnedFooter
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: pinnedBodyPadding,
                    child: formFields,
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: pinnedBodyPadding,
                    child: actionsSection,
                  ),
                ),
              ],
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.embedded
                    ? double.infinity
                    : MediaQuery.sizeOf(context).height *
                        DesignMetrics.dialogBodyMaxHeightFraction,
              ),
              child: SingleChildScrollView(
                child: formFields,
              ),
            ),
    );

    if (widget.embedded) {
      if (widget.pinnedFooter) {
        return formBody;
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          formBody,
          SizedBox(height: s.md),
          actionsSection,
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(widget.isEditing ? 'Editar produto' : 'Novo produto'),
      content: formBody,
      actions: actions,
    );
  }
}

Future<ProdutoFormDialogResult?> showProdutoFormDialog(
  BuildContext context, {
  Product? product,
}) {
  final titleText = product != null ? 'Editar produto' : 'Novo produto';
  final title = Text(titleText);
  return AdaptiveNavigator.open<ProdutoFormDialogResult>(
    context: context,
    sideSheetWidth: AdaptiveNavigator.isDesktop(context) ? 640 : 520,
    routeSettings: RouteSettings(
      name: product == null ? '/produtos/novo' : '/produtos/${product.id}/editar',
    ),
    builder: (formContext) {
      if (AdaptiveNavigator.isMobile(formContext)) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: SafeArea(
            child: ProdutoFormDialog(
              product: product,
              embedded: true,
              pinnedFooter: true,
            ),
          ),
        );
      }

      return _ProdutoFormSideSheet(
        title: titleText,
        child: ProdutoFormDialog(
          product: product,
          embedded: true,
          pinnedFooter: true,
        ),
      );
    },
  );
}

class _ProdutoFormSideSheet extends StatelessWidget {
  const _ProdutoFormSideSheet({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.sm, s.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.erpCardTitle,
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => AdaptiveNavigator.close(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(s.lg),
            child: child,
          ),
        ),
      ],
    );
  }
}

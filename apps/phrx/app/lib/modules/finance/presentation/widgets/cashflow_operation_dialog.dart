import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';
import '../../data/repositories/cashflow_repository_impl.dart';
import '../../domain/entities/cashflow_operation.dart';

Future<CashflowOperationResponse?> showCashflowOperationDialog(
  BuildContext context, {
  required CashflowOperationKind kind,
}) {
  final title = Text('Fluxo de Caixa - ${kind.label}');
  final width = AdaptiveNavigator.widthOf(context);
  final panelWidth =
      width >= AdaptiveSideSheetMetrics.desktopBreakpoint ? 520.0 : 480.0;

  return AdaptiveNavigator.openPanel<CashflowOperationResponse>(
    context: context,
    sideSheetWidth: panelWidth,
    routeSettings: RouteSettings(name: '/finance/operation/${kind.name}'),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: CashflowOperationDialog(
                kind: kind,
                embedded: true,
              ),
            ),
          ),
        );
      }
      return CashflowOperationDialog(
        kind: kind,
        embedded: true,
        showHeader: true,
        onClose: () => AdaptiveNavigator.cancel(detailContext),
      );
    },
  );
}

class CashflowOperationDialog extends ConsumerStatefulWidget {
  const CashflowOperationDialog({
    required this.kind,
    this.embedded = false,
    this.showHeader = false,
    this.onClose,
    super.key,
  });

  final CashflowOperationKind kind;
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<CashflowOperationDialog> createState() =>
      _CashflowOperationDialogState();
}

class _CashflowOperationDialogState
    extends ConsumerState<CashflowOperationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valorController;
  late final TextEditingController _descricaoController;

  CashflowContext? _context;
  String? _origem;
  String? _loadError;
  var _loadingContext = true;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController();
    _descricaoController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContext());
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    setState(() {
      _loadingContext = true;
      _loadError = null;
    });

    try {
      final ctx = await ref.read(cashflowRepositoryProvider).getContext();
      if (!mounted) return;

      final suggested = suggestedOrigemForKind(widget.kind);
      final origemValues = ctx.origens.map((o) => o.value).toSet();
      final initialOrigem = suggested != null && origemValues.contains(suggested)
          ? suggested
          : null;

      setState(() {
        _context = ctx;
        _origem = initialOrigem;
        _loadingContext = false;
      });
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loadingContext = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Não foi possível carregar o saldo do caixa. Verifique a sessão no POS.';
        _loadingContext = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting || _context == null) return;
    if (_formKey.currentState?.validate() != true) return;

    final origem = _origem;
    if (origem == null || origem.isEmpty) {
      PharmaFeedback.warning(context, 'Selecione a origem/destino.');
      return;
    }

    final valor = parseCashflowMoney(_valorController.text);
    if (valor == null || valor <= 0) {
      PharmaFeedback.warning(context, 'Informe um valor válido maior que zero.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final response = await ref.read(cashflowRepositoryProvider).registerOperation(
            kind: widget.kind,
            request: CashflowOperationRequest(
              valor: valor,
              origem: origem,
              descricao: _descricaoController.text.trim().isEmpty
                  ? null
                  : _descricaoController.text.trim(),
            ),
          );
      if (!mounted) return;
      AdaptiveNavigator.complete(context, response);
    } on ApiFailure catch (e) {
      if (!mounted) return;
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha na operação',
        message: e.message,
      );
    } catch (_) {
      if (!mounted) return;
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha na operação',
        message: 'Não foi possível concluir a operação de fluxo de caixa.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final cashflow = _context;
    final canSubmit = !_loadingContext &&
        !_submitting &&
        cashflow != null &&
        _loadError == null;

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Caixa Ativo', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: s.sm),
          if (_loadingContext) ...[
            const LinearProgressIndicator(minHeight: 2),
            SizedBox(height: s.md),
            Text(
              'A carregar saldo e opções...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.textMuted,
                  ),
            ),
          ] else if (_loadError != null) ...[
            Text(
              _loadError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.posDanger,
                  ),
            ),
            SizedBox(height: s.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _submitting ? null : _loadContext,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ),
          ] else if (cashflow != null) ...[
            Container(
              padding: EdgeInsets.all(s.md),
              decoration: BoxDecoration(
                color: t.bgSecondary,
                borderRadius: BorderRadius.circular(t.radiusMd),
                border: Border.all(color: t.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cashflow.terminal.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: t.textMuted,
                        ),
                  ),
                  SizedBox(height: s.xs),
                  Text(
                    'Saldo do Caixa',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: t.textMuted,
                        ),
                  ),
                  SizedBox(height: s.xxs),
                  Text(
                    formatCashflowMoney(cashflow.saldoAtual),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: s.md),
            TextFormField(
              controller: _valorController,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
                suffixText: 'MZN',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (value) {
                final parsed = parseCashflowMoney(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Valor obrigatório e maior que zero';
                }
                return null;
              },
            ),
            SizedBox(height: s.md),
            DropdownButtonFormField<String>(
              key: ValueKey('origem-${cashflow.caixaId}-$_origem'),
              initialValue: _origem != null &&
                      cashflow.origens.any((o) => o.value == _origem)
                  ? _origem
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Origem / Destino',
                border: OutlineInputBorder(),
              ),
              items: cashflow.origens
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option.value,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _origem = value),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Selecione a origem' : null,
            ),
            SizedBox(height: s.md),
            TextFormField(
              controller: _descricaoController,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
    );

    final actions = [
      OutlinedButton(
        onPressed: _submitting ? null : () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: canSubmit ? _submit : null,
        child: _submitting
            ? const PharmaButtonLoader()
            : const Text('Confirmar'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fluxo de Caixa - ${widget.kind.label}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: _submitting ? null : widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: form,
            ),
          ),
          if (widget.showHeader) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text('Fluxo de Caixa - ${widget.kind.label}'),
      content: form,
      actions: actions,
    );
  }
}

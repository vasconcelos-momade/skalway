import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../domain/entities/caixa_disponivel.dart';
import '../../domain/entities/caixa_sessao.dart';
import '../providers/caixa_sessao_provider.dart';

double? parseCaixaMoneyInput(String raw) {
  final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

/// Valor de abertura: vazio → 0; apenas negativos são inválidos.
double parseCaixaMoneyInputOrZero(String raw) {
  final parsed = parseCaixaMoneyInput(raw);
  return parsed ?? 0;
}

String formatCaixaMoney(num value) {
  return '${value.toStringAsFixed(2)} MT';
}

Future<void> showAbrirCaixaDialog(BuildContext context) {
  return AdaptiveNavigator.openEmbeddedForm<void>(
    context: context,
    title: const Text('Abrir Caixa'),
    routeSettings: const RouteSettings(name: '/pdv/caixa/abrir'),
    formBuilder: (ctx, {required embedded}) =>
        AbrirCaixaDialog(embedded: embedded),
  );
}

Future<void> showFecharCaixaDialog(
  BuildContext context, {
  required CaixaSessao sessao,
}) {
  return AdaptiveNavigator.openEmbeddedForm<void>(
    context: context,
    title: const Text('Fechar Caixa'),
    routeSettings: RouteSettings(name: '/pdv/caixa/${sessao.id}/fechar'),
    formBuilder: (ctx, {required embedded}) =>
        FecharCaixaDialog(sessao: sessao, embedded: embedded),
  );
}

class AbrirCaixaDialog extends ConsumerStatefulWidget {
  const AbrirCaixaDialog({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<AbrirCaixaDialog> createState() => _AbrirCaixaDialogState();
}

class _AbrirCaixaDialogState extends ConsumerState<AbrirCaixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController(text: '0');
  CaixaDisponivel? _selectedCaixa;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(caixaSessaoProvider.notifier)
          .loadCaixasDisponiveis(force: true)
          .catchError((_) {});
    });
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final caixa = _selectedCaixa;
    if (caixa == null) {
      PharmaFeedback.warning(
        context,
        'Selecione um terminal antes de continuar.',
      );
      return;
    }

    final valorAbertura = parseCaixaMoneyInputOrZero(_valorController.text);
    if (valorAbertura < 0) {
      PharmaFeedback.warning(
        context,
        'O valor de abertura nao pode ser negativo.',
      );
      return;
    }

    try {
      await ref.read(caixaSessaoProvider.notifier).abrirCaixa(
            caixaId: caixa.caixaId,
            valorAbertura: valorAbertura,
          );
      if (!mounted) return;
      AdaptiveNavigator.complete(context);
      PharmaFeedback.success(context, 'Caixa aberto com sucesso.');
    } catch (_) {
      if (!mounted) return;
      final message = ref.read(caixaSessaoProvider).errorMessage ??
          'Nao foi possivel abrir o caixa.';
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha ao abrir caixa',
        message: message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final caixaState = ref.watch(caixaSessaoProvider);
    final caixas = caixaState.caixasDisponiveis;
    final selectedValue = caixas.contains(_selectedCaixa) ? _selectedCaixa : null;

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (caixaState.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.md),
              child: Text(
                caixaState.errorMessage!,
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                      color: t.posDanger,
                    ),
              ),
            ),
          DropdownButtonFormField<CaixaDisponivel>(
            initialValue: selectedValue,
            isExpanded: true,
            items: caixas
                .map(
                  (caixa) => DropdownMenuItem<CaixaDisponivel>(
                    value: caixa,
                    child: Text(
                      caixa.displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
            onChanged: caixaState.isSubmitting
                ? null
                : (value) {
                    setState(() {
                      _selectedCaixa = value;
                    });
                  },
            decoration: const InputDecoration(
              labelText: 'Selecionar Terminal',
              prefixIcon: Icon(Icons.devices_other_outlined),
            ),
            validator: (value) {
              if (value == null) {
                return 'Selecione um terminal.';
              }
              return null;
            },
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor de abertura',
              prefixIcon: Icon(Icons.payments_outlined),
              suffixText: 'MT',
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return null;
              }
              final parsed = parseCaixaMoneyInput(text);
              if (parsed == null) {
                return 'Valor invalido.';
              }
              if (parsed < 0) {
                return 'O valor nao pode ser negativo.';
              }
              return null;
            },
          ),
          if (caixaState.isLoading) ...[
            SizedBox(height: s.md),
            LinearProgressIndicator(minHeight: s.xxs),
          ],
          if (!caixaState.isLoading && caixas.isEmpty) ...[
            SizedBox(height: s.md),
            Text(
              'Nenhum terminal disponivel para abertura de caixa.',
              style: Theme.of(context).textTheme.erpCaption.copyWith(
                    color: t.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );

    final actions = [
      TextButton(
        onPressed:
            caixaState.isSubmitting ? null : () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: caixaState.isSubmitting || caixas.isEmpty ? null : _submit,
        icon: caixaState.isSubmitting
            ? const PharmaButtonLoader()
            : const Icon(Icons.lock_open_rounded),
        label: const Text('Abrir Caixa'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          form,
          SizedBox(height: s.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: const Text('Abrir Caixa'),
      content: form,
      actions: actions,
    );
  }
}

class FecharCaixaDialog extends ConsumerStatefulWidget {
  const FecharCaixaDialog({
    required this.sessao,
    super.key,
    this.embedded = false,
  });

  final CaixaSessao sessao;
  final bool embedded;

  @override
  ConsumerState<FecharCaixaDialog> createState() => _FecharCaixaDialogState();
}

class _FecharCaixaDialogState extends ConsumerState<FecharCaixaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valorContadoController;
  final _observacoesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _valorContadoController = TextEditingController(
      text: widget.sessao.sistema.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _valorContadoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final valorContado = parseCaixaMoneyInput(_valorContadoController.text);
    if (valorContado == null || valorContado < 0) {
      PharmaFeedback.warning(
        context,
        'Informe um valor contado valido.',
      );
      return;
    }

    try {
      await ref.read(caixaSessaoProvider.notifier).fecharCaixa(
            sessaoId: widget.sessao.id,
            valorContado: valorContado,
            observacoes: _observacoesController.text.trim().isEmpty
                ? null
                : _observacoesController.text.trim(),
          );
      if (!mounted) return;
      AdaptiveNavigator.complete(context);
      PharmaFeedback.success(context, 'Caixa fechado com sucesso.');
    } catch (_) {
      if (!mounted) return;
      final message = ref.read(caixaSessaoProvider).errorMessage ??
          'Nao foi possivel fechar o caixa.';
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha ao fechar caixa',
        message: message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final caixaState = ref.watch(caixaSessaoProvider);

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  'Valor de sistema',
                  style: Theme.of(context).textTheme.erpCaption.copyWith(
                        color: t.textMuted,
                      ),
                ),
                SizedBox(height: s.xs),
                Text(
                  formatCaixaMoney(widget.sessao.sistema),
                  style: Theme.of(context).textTheme.erpAppBarTitle.copyWith(
                        color: t.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _valorContadoController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor contado',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              suffixText: 'MT',
            ),
            validator: (value) {
              final parsed = parseCaixaMoneyInput(value ?? '');
              if (parsed == null || parsed < 0) {
                return 'Informe um valor valido.';
              }
              return null;
            },
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _observacoesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observacoes do fecho',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );

    final actions = [
      TextButton(
        onPressed:
            caixaState.isSubmitting ? null : () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: caixaState.isSubmitting ? null : _submit,
        icon: caixaState.isSubmitting
            ? const PharmaButtonLoader()
            : const Icon(Icons.lock_outline_rounded),
        label: const Text('Fechar Caixa'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          form,
          SizedBox(height: s.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: const Text('Fechar Caixa'),
      content: form,
      actions: actions,
    );
  }
}

class CaixaFechadoBanner extends StatelessWidget {
  const CaixaFechadoBanner({
    super.key,
    required this.onAbrirCaixa,
    this.compact = false,
  });

  final VoidCallback onAbrirCaixa;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Material(
      color: t.posDanger.withValues(alpha: compact ? 0.1 : 0.12),
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Padding(
        padding: EdgeInsets.all(compact ? s.sm : s.md),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: t.posDanger,
              size: compact ? t.iconSm : t.iconMd,
            ),
            SizedBox(width: s.sm),
            Expanded(
              child: Text(
                'Abra o caixa para iniciar as operacoes.',
                style: (compact
                        ? Theme.of(context).textTheme.erpCaption
                        : Theme.of(context).textTheme.erpBodySecondary).copyWith(
                  color: compact ? t.posDanger : t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAbrirCaixa,
              icon: Icon(Icons.lock_open_rounded, size: t.iconSm),
              label: const Text('Abrir caixa'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? s.sm : s.md,
                  vertical: compact ? s.xs : s.sm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

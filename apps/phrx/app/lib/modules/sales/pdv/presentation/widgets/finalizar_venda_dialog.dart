import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/design_metrics.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/inputs/async_type_ahead_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../customers/data/repositories/customer_repository_impl.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../domain/entities/pdv_checkout.dart';
import '../providers/pdv_cart_provider.dart';
import '../providers/pdv_checkout_provider.dart';

Future<PdvCheckoutResult?> showFinalizarVendaDialog(
  BuildContext context, {
  required double total,
  required bool requiresPatientDetails,
}) {
  return AdaptiveNavigator.openEmbeddedForm<PdvCheckoutResult>(
    context: context,
    title: const Text('Finalizar Venda'),
    routeSettings: const RouteSettings(name: '/pdv/checkout'),
    mobileWrapInScrollView: false,
    formBuilder: (ctx, {required embedded}) => FinalizarVendaDialog(
      total: total,
      requiresPatientDetails: requiresPatientDetails,
      embedded: embedded,
    ),
  );
}

enum FinalizarVendaPresentation {
  dialog,
  screen,
}

class FinalizarVendaDialog extends ConsumerStatefulWidget {
  const FinalizarVendaDialog({
    super.key,
    required this.total,
    required this.requiresPatientDetails,
    this.presentation = FinalizarVendaPresentation.dialog,
    this.embedded = false,
  });

  final double total;
  final bool requiresPatientDetails;
  final FinalizarVendaPresentation presentation;
  final bool embedded;

  @override
  ConsumerState<FinalizarVendaDialog> createState() =>
      _FinalizarVendaDialogState();
}

class _FinalizarVendaDialogState
    extends ConsumerState<FinalizarVendaDialog> {
  static const int _maxPatientAge = 130;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _idadeController;
  late final TextEditingController _nidController;
  late final TextEditingController _prescritorController;
  late final TextEditingController _unidadeSanitariaController;
  late final TextEditingController _valorRecebidoController;

  PdvPaymentMethod _selectedMethod = PdvPaymentMethod.dinheiro;
  bool _isApplyingCustomerSelection = false;

  bool get _isCashPayment => _selectedMethod == PdvPaymentMethod.dinheiro;

  double? get _valorRecebido => _parseCheckoutMoneyInput(
        _valorRecebidoController.text,
      );

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _idadeController = TextEditingController();
    _nidController = TextEditingController();
    _prescritorController = TextEditingController();
    _unidadeSanitariaController = TextEditingController();
    _valorRecebidoController = TextEditingController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _nidController.dispose();
    _prescritorController.dispose();
    _unidadeSanitariaController.dispose();
    _valorRecebidoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final checkoutState = ref.read(pdvCheckoutProvider);
    final cartState = ref.read(pdvCartProvider);
    if (checkoutState.isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final idadeTexto = _idadeController.text.trim();
    if (idadeTexto.isNotEmpty) {
      final idade = int.tryParse(idadeTexto);
      if (idade == null || idade <= 0 || idade > _maxPatientAge) {
        await PharmaFeedback.criticalError(
          context: context,
          title: 'Idade inválida',
          message: 'Informe uma idade entre 1 e $_maxPatientAge anos.',
        );
        return;
      }
    }

    if (_isCashPayment) {
      final recebido = _parseCheckoutMoneyInput(_valorRecebidoController.text);
      if (recebido == null) {
        await PharmaFeedback.criticalError(
          context: context,
          title: 'Valor recebido inválido',
          message: 'Informe o valor recebido para o pagamento em dinheiro.',
        );
        return;
      }
    }

    try {
      final nomeDigitado = _nomeController.text.trim();
      final nomePaciente = cartState.hasSelectedCliente
          ? cartState.selectedClienteNome?.trim()
          : (nomeDigitado.isEmpty ? null : nomeDigitado);
      final idadeTexto = _idadeController.text.trim();
      final nid = _nidController.text.trim();
      final prescritor = _prescritorController.text.trim();
      final unidadeSanitaria = _unidadeSanitariaController.text.trim();
      final paciente = widget.requiresPatientDetails
          ? PdvCheckoutPatient(
              nome: nomePaciente,
              idade: idadeTexto.isEmpty ? null : int.tryParse(idadeTexto),
              nid: nid.isEmpty ? null : nid,
              prescritor: prescritor.isEmpty ? null : prescritor,
              unidadeSanitaria: unidadeSanitaria.isEmpty
                  ? null
                  : unidadeSanitaria,
            )
          : null;

      final result = await ref.read(pdvCheckoutProvider.notifier).finalizarVenda(
            metodoPagamento: _selectedMethod,
            valorRecebido: _isCashPayment ? _valorRecebido : null,
            paciente: paciente,
            nomeClienteDigitado: nomeDigitado,
            criarClienteSeNecessario:
                !cartState.hasSelectedCliente && nomeDigitado.isNotEmpty,
          );

      if (!mounted) {
        return;
      }
      AdaptiveNavigator.complete(context, result);
    } on ApiFailure catch (e) {
      if (!mounted) {
        return;
      }
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha ao finalizar venda',
        message: e.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha ao finalizar venda',
        message: 'Não foi possível concluir a venda. Tente novamente.',
      );
    }
  }

  Future<List<CustomerSummary>> _searchCustomers(String query) async {
    final response = await ref.read(customerRepositoryProvider).listCustomers(
          CustomerQuery(
            page: 1,
            pageSize: 8,
            search: query,
          ),
        );
    return response.items
        .where(
          (customer) =>
              customer.nome.trim().toLowerCase() !=
              PdvCartState.defaultClienteLabel.toLowerCase(),
        )
        .toList(growable: false);
  }

  void _applySelectedCustomer(CustomerSummary customer) {
    _isApplyingCustomerSelection = true;
    _nomeController
      ..text = customer.nome
      ..selection = TextSelection.collapsed(offset: customer.nome.length);
    ref.read(pdvCartProvider.notifier).setSelectedCliente(
          id: customer.id,
          nome: customer.nome,
        );
    _isApplyingCustomerSelection = false;
  }

  void _handleNomeChanged(String value) {
    if (_isApplyingCustomerSelection) {
      return;
    }
    final trimmed = value.trim();
    final cartState = ref.read(pdvCartProvider);
    final selectedName = cartState.selectedClienteNome?.trim();
    if (
      cartState.hasSelectedCliente &&
      (selectedName == null || trimmed.toLowerCase() != selectedName.toLowerCase())
    ) {
      ref.read(pdvCartProvider.notifier).clearSelectedCliente();
    }
  }

  Widget _buildNomeField(PdvCartState cartState) {
    return AsyncTypeAheadField<CustomerSummary>(
      controller: _nomeController,
      labelText: 'Nome do paciente',
      floatingLabel: true,
      helperText: cartState.hasSelectedCliente
          ? 'Cliente encontrado e associado a venda.'
          : 'Opcional. Pesquise um cliente ou digite um novo nome.',
      emptyMessage:
          'Nenhum cliente encontrado. Continue a digitar para usar como novo registo.',
      suggestionsCallback: (query) async {
        try {
          return await _searchCustomers(query);
        } catch (_) {
          return const <CustomerSummary>[];
        }
      },
      itemLabel: (customer) => customer.nome,
      itemSubtitle: (customer) => customer.telefone ?? '',
      onSelected: _applySelectedCustomer,
      onChanged: _handleNomeChanged,
    );
  }

  Widget _buildIdadeField() {
    return EnterpriseTextFormField(
      controller: _idadeController,
      labelText: 'Idade',
      floatingLabel: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return null;
        }
        final idade = int.tryParse(trimmed);
        if (idade == null || idade <= 0 || idade > _maxPatientAge) {
          return 'Informe uma idade entre 1 e $_maxPatientAge anos.';
        }
        return null;
      },
    );
  }

  Widget _buildNidField() {
    return EnterpriseTextFormField(
      controller: _nidController,
      labelText: 'NID da receita/doente',
      floatingLabel: true,
    );
  }

  Widget _buildPrescritorField() {
    return EnterpriseTextFormField(
      controller: _prescritorController,
      labelText: 'Prescritor',
      floatingLabel: true,
    );
  }

  Widget _buildUnidadeSanitariaField() {
    return EnterpriseTextFormField(
      controller: _unidadeSanitariaController,
      labelText: 'Unidade sanitária',
      floatingLabel: true,
    );
  }

  Widget _buildValorRecebidoField(bool enabled) {
    return EnterpriseTextFormField(
      controller: _valorRecebidoController,
      enabled: enabled,
      labelText: 'Valor recebido *',
      floatingLabel: true,
      suffixText: 'MT',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      validator: (value) {
        if (!_isCashPayment) {
          return null;
        }
        final recebido = _parseCheckoutMoneyInput(value ?? '');
        if (recebido == null) {
          return 'Informe o valor recebido.';
        }
        return null;
      },
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    PdvCheckoutState checkoutState,
    FinalizarVendaPresentation presentation,
  ) {
    final cancelButton = OutlinedButton(
      onPressed: checkoutState.isSubmitting
          ? null
          : () => AdaptiveNavigator.cancel(context),
      child: const Text('Cancelar'),
    );

    final confirmButton = FilledButton(
      onPressed: checkoutState.isSubmitting ? null : _submit,
      child: checkoutState.isSubmitting
          ? const PharmaButtonLoader()
          : const Text('Finalizar venda'),
    );

    if (widget.embedded) {
      return [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(child: cancelButton),
              SizedBox(width: context.spacing.md),
              Expanded(child: confirmButton),
            ],
          ),
        ),
      ];
    }

    if (presentation == FinalizarVendaPresentation.screen) {
      return [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(child: cancelButton),
              SizedBox(width: context.spacing.md),
              Expanded(child: confirmButton),
            ],
          ),
        ),
      ];
    }

    return [
      cancelButton,
      confirmButton,
    ];
  }

  Widget _buildMobileFooter(BuildContext context, List<Widget> actions) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    // Mesma margem horizontal da página (s.md).
    final horizontal = PharmaScreenLayout.mobileHorizontalInset(context);

    return Material(
      color: t.bgPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, s.sm, horizontal, s.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    PdvCheckoutState checkoutState,
  ) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final cartState = ref.watch(pdvCartProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CheckoutSummaryCard(total: widget.total),
          SizedBox(height: s.lg),
          if (widget.requiresPatientDetails)
            _ResponsiveFormGrid(
              items: [
                _ResponsiveFormGridItem(
                  child: _buildNomeField(cartState),
                  mobileSpan: 1,
                  tabletSpan: 2,
                  desktopSpan: 2,
                ),
                _ResponsiveFormGridItem(
                  child: _buildIdadeField(),
                  mobileSpan: 1,
                ),
                _ResponsiveFormGridItem(
                  child: _buildNidField(),
                  mobileSpan: 1,
                ),
                _ResponsiveFormGridItem(
                  child: _buildPrescritorField(),
                  mobileSpan: 1,
                ),
                _ResponsiveFormGridItem(
                  child: _buildUnidadeSanitariaField(),
                  mobileSpan: 1,
                ),
              ],
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 2,
            )
          else
            _buildNomeField(cartState),
          SizedBox(height: s.lg),
          Text(
            'Método de pagamento',
            style: Theme.of(context).textTheme.erpTabLabel.copyWith(
                  color: t.textPrimary,
                ),
          ),
          SizedBox(height: s.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.sizeOf(context).width;
              final columns = _responsiveColumnCount(
                screenWidth,
                mobileColumns: 2,
                tabletColumns: 2,
                desktopColumns: 4,
              );
              final spacing = s.sm;
              final totalSpacing = spacing * (columns - 1);
              final itemWidth =
                  (constraints.maxWidth - totalSpacing) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: PdvPaymentMethod.values
                    .map(
                      (method) => SizedBox(
                        width: itemWidth,
                        child: _PaymentMethodCard(
                          method: method,
                          selected: method == _selectedMethod,
                          onTap: checkoutState.isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _selectedMethod = method;
                                  });
                                },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (_isCashPayment) ...[
            SizedBox(height: s.md),
            _buildValorRecebidoField(!checkoutState.isSubmitting),
          ],
          if (checkoutState.errorMessage != null) ...[
            SizedBox(height: s.md),
            Container(
              padding: EdgeInsets.all(s.sm),
              decoration: BoxDecoration(
                color: t.posDanger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.card(t)),
                border: Border.all(
                  color: t.posDanger.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                checkoutState.errorMessage!,
                style: Theme.of(context).textTheme.erpCaption.copyWith(
                      color: t.posDanger,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final checkoutState = ref.watch(pdvCheckoutProvider);
    final actions = _buildActions(context, checkoutState, widget.presentation);
    final content = _buildFormContent(context, checkoutState);

    if (widget.embedded) {
      if (AdaptiveNavigator.isMobile(context)) {
        final horizontal = PharmaScreenLayout.mobileHorizontalInset(context);
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, s.lg, horizontal, s.md),
                child: content,
              ),
            ),
            _buildMobileFooter(context, actions),
          ],
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          SizedBox(height: s.lg),
          ...actions,
        ],
      );
    }

    if (widget.presentation == FinalizarVendaPresentation.screen) {
      final horizontal = PharmaScreenLayout.mobileHorizontalInset(context);
      return PopScope(
        canPop: !checkoutState.isSubmitting,
        child: Scaffold(
          backgroundColor: t.bgPrimary,
          appBar: AppBar(
            leading: BackButton(
              onPressed: checkoutState.isSubmitting
                  ? null
                  : () => AdaptiveNavigator.cancel(context),
            ),
            title: const Text('Finalizar Venda'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      s.lg,
                      horizontal,
                      s.md,
                    ),
                    child: content,
                  ),
                ),
                _buildMobileFooter(context, actions),
              ],
            ),
          ),
        ),
      );
    }

    return PharmaResponsiveDialog(
      title: Text(
        'Finalizar Venda',
        style: Theme.of(context).textTheme.erpCardTitle.copyWith(
              color: t.textPrimary,
            ),
      ),
      content: content,
      actions: actions,
    );
  }
}

class _CheckoutSummaryCard extends StatelessWidget {
  const _CheckoutSummaryCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.brandGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card(t)),
        border: Border.all(
          color: t.brandGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total a pagar',
            style: Theme.of(context).textTheme.erpTabLabel.copyWith(
                  color: t.textPrimary,
                ),
          ),
          Text(
            _formatCheckoutMoney(total),
            style: Theme.of(context).textTheme.erpAppBarTitle.copyWith(
                  color: t.brandGreen,
                ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PdvPaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final descriptor = _descriptorFor(method);

    return Material(
      color: t.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card(t)),
        child: Ink(
          padding: EdgeInsets.all(s.md),
          decoration: BoxDecoration(
            color: selected ? t.brandBlue.withValues(alpha: 0.14) : t.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadius.card(t)),
            border: Border.all(
              color: selected
                  ? t.brandBlue
                  : t.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                descriptor.icon,
                color: selected ? t.brandBlue : t.textSecondary,
                size: t.iconMd,
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: Text(
                  descriptor.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.erpTabLabel.copyWith(
                        color: t.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, String label}) _descriptorFor(PdvPaymentMethod value) {
    switch (value) {
      case PdvPaymentMethod.dinheiro:
        return (icon: Icons.payments_outlined, label: 'Dinheiro');
      case PdvPaymentMethod.mpesa:
        return (icon: Icons.phone_android_rounded, label: 'M-Pesa');
      case PdvPaymentMethod.emola:
        return (icon: Icons.account_balance_wallet_outlined, label: 'E-Mola');
      case PdvPaymentMethod.cartao:
        return (icon: Icons.credit_card_rounded, label: 'Cartão');
    }
  }
}

class _ResponsiveFormGrid extends StatelessWidget {
  const _ResponsiveFormGrid({
    required this.items,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  });

  final List<_ResponsiveFormGridItem> items;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _responsiveColumnCount(
          screenWidth,
          mobileColumns: mobileColumns,
          tabletColumns: tabletColumns,
          desktopColumns: desktopColumns,
        );
        final spacing = s.md;
        final totalSpacing = spacing * (columns - 1);
        final baseItemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            final span = item.spanForWidth(
              screenWidth,
              maxColumns: columns,
            );
            final width = (baseItemWidth * span) + (spacing * (span - 1));
            return SizedBox(
              width: width,
              child: item.child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ResponsiveFormGridItem {
  const _ResponsiveFormGridItem({
    required this.child,
    this.mobileSpan = 1,
    this.tabletSpan = 1,
    this.desktopSpan = 1,
  });

  final Widget child;
  final int mobileSpan;
  final int tabletSpan;
  final int desktopSpan;

  int spanForWidth(double width, {required int maxColumns}) {
    final span = switch (_layoutBreakpointForWidth(width)) {
      _ResponsiveLayoutBreakpoint.mobile => mobileSpan,
      _ResponsiveLayoutBreakpoint.tablet => tabletSpan,
      _ResponsiveLayoutBreakpoint.desktop => desktopSpan,
    };
    if (span < 1) {
      return 1;
    }
    if (span > maxColumns) {
      return maxColumns;
    }
    return span;
  }
}

enum _ResponsiveLayoutBreakpoint {
  mobile,
  tablet,
  desktop,
}

_ResponsiveLayoutBreakpoint _layoutBreakpointForWidth(double width) {
  if (width < DesignMetrics.breakpointMobile) {
    return _ResponsiveLayoutBreakpoint.mobile;
  }
  if (width < DesignMetrics.breakpointTablet) {
    return _ResponsiveLayoutBreakpoint.tablet;
  }
  return _ResponsiveLayoutBreakpoint.desktop;
}

int _responsiveColumnCount(
  double width, {
  int mobileColumns = 1,
  int tabletColumns = 2,
  int desktopColumns = 4,
}) {
  return switch (_layoutBreakpointForWidth(width)) {
    _ResponsiveLayoutBreakpoint.mobile => mobileColumns,
    _ResponsiveLayoutBreakpoint.tablet => tabletColumns,
    _ResponsiveLayoutBreakpoint.desktop => desktopColumns,
  };
}

double? _parseCheckoutMoneyInput(String raw) {
  final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

String _formatCheckoutMoney(num value) {
  final amount = value.toDouble();
  final hasDecimals = amount != amount.truncateToDouble();
  return '${amount.toStringAsFixed(hasDecimals ? 2 : 0)} MT';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/errors/api_failure.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
import '../../modules/sales/proforma_invoices/presentation/providers/proforma_invoice_cart_provider.dart';
import '../../modules/sales/proforma_invoices/presentation/widgets/save_proforma_invoice_dialog.dart';
import '../widgets/feedback/pharma_feedback.dart';
import '../responsive/pharma_screen_layout.dart';

/// Shell full-screen da Fatura Proforma, alinhado ao chrome do PDV.
class ProformaLayout extends ConsumerWidget {
  const ProformaLayout({super.key, required this.child});

  final Widget child;

  void _handleExit(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(AppRoutePaths.dashboard);
  }

  Future<void> _startNewInvoice(BuildContext context, WidgetRef ref) async {
    final cartNotifier = ref.read(proformaInvoiceCartProvider.notifier);
    final cartState = ref.read(proformaInvoiceCartProvider);
    if (cartState.hasProformaInvoice) {
      cartNotifier.resetComposer();
    }

    final result = await showSaveProformaInvoiceDialog(context);
    if (!context.mounted || result == null) {
      return;
    }

    try {
      await cartNotifier.createProformaInvoice(header: result);
      if (!context.mounted) {
        return;
      }
      final state = ref.read(proformaInvoiceCartProvider);
      PharmaFeedback.success(
        context,
        'Fatura Proforma ${state.proformaInvoiceNumero} criada e persistida no backend.',
      );
    } on ApiFailure catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final horizontalInset = isMobile
        ? PharmaScreenLayout.mobileHorizontalInset(context)
        : t.density.gutter;
    final proformaState = ref.watch(proformaInvoiceCartProvider);
    final canStartNewInvoice =
        !proformaState.isBusy && !proformaState.isSavingHeader;

    return Scaffold(
      backgroundColor: t.bgPrimary,
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgSecondary,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: t.posHeader,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: LayoutBuilder(
                    builder: (context, bx) {
                      final narrow = bx.maxWidth < Breakpoints.mobile;
                      return Row(
                        children: [
                          SizedBox.square(
                            dimension: t.controlHeight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(t.radiusMd),
                              child: Image.asset(
                                'assets/logos/logo_512.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: narrow ? s.sm : s.md),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'PhRx',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .erpAppName
                                        .copyWith(color: t.textPrimary),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: s.sm),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: t.iconSm,
                                    color: t.border,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    'Fatura Proforma',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: t.textPrimary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (narrow)
                            SizedBox.square(
                              dimension: t.controlHeight,
                              child: IconButton(
                                tooltip: ' Nova Fatura',
                                onPressed: canStartNewInvoice
                                    ? () => _startNewInvoice(context, ref)
                                    : null,
                                icon: Icon(
                                  Icons.add_rounded,
                                  color: t.brandGreen,
                                ),
                              ),
                            )
                          else
                            FilledButton.icon(
                              onPressed: canStartNewInvoice
                                  ? () => _startNewInvoice(context, ref)
                                  : null,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nova Fatura'),
                            ),
                          SizedBox(width: narrow ? s.sm : s.lg),
                          if (narrow)
                            SizedBox.square(
                              dimension: t.controlHeight,
                              child: IconButton(
                                tooltip: 'Sair da Página',
                                onPressed: () => _handleExit(context),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: t.textSecondary,
                                ),
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: () => _handleExit(context),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: t.textSecondary,
                                size: t.iconSm,
                              ),
                              label: Text(
                                'Sair da Página',
                                style: Theme.of(context)
                                    .textTheme
                                    .erpLabel
                                    .copyWith(color: t.textSecondary),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

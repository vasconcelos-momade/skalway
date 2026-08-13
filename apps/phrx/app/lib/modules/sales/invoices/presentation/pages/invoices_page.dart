import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/component_theme.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../reports/presentation/controllers/report_controller.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../domain/entities/invoice_summary.dart';
import '../providers/invoice_action_provider.dart';
import '../providers/invoice_detail_provider.dart';
import '../providers/invoice_list_provider.dart';
import '../widgets/cancel_invoice_dialog.dart';
import '../widgets/invoice_detail_screen.dart';
import '../widgets/invoices_body.dart';
import '../../../../../shared/refresh/page_refresh.dart';

class SalesInvoicesPage extends ConsumerStatefulWidget {
  const SalesInvoicesPage({super.key});

  @override
  ConsumerState<SalesInvoicesPage> createState() => _SalesInvoicesPageState();
}

class _SalesInvoicesPageState extends ConsumerState<SalesInvoicesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(invoiceListProvider).query.search;
    _searchController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InvoiceActionState>(invoiceActionProvider, (previous, next) {
      if (!mounted || previous == next) {
        return;
      }
      final previousSubmitting = previous?.isSubmitting ?? false;
      if (previousSubmitting &&
          !next.isSubmitting &&
          next.errorMessage == null) {
        PharmaFeedback.success(context, 'Fatura cancelada com sucesso.');
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        PharmaFeedback.error(context, next.errorMessage!);
      }
    });

    final listState = ref.watch(invoiceListProvider);
    final detailState = ref.watch(invoiceDetailProvider);
    final reportState = ref.watch(reportControllerProvider);
    final reportController = ref.read(reportControllerProvider.notifier);
    final query = listState.query;
    final reportQuery = _buildReportQuery(query);

    if (_searchController.text != query.search) {
      _searchController.value = TextEditingValue(
        text: query.search,
        selection: TextSelection.collapsed(offset: query.search.length),
      );
    }

    return PageRefreshBinder(
      onRefresh: () => ref.read(invoiceListProvider.notifier).refresh(),
      child: EnterpriseModuleHub(
      title: 'Faturas de venda',
      subtitle:
          'Histórico operacional do POS com pesquisa, filtros rápidos, cache em memória e cancelamento seguro.',
      tag: 'Terminal',
      actions: [
        Builder(
          builder: (anchorContext) {
            final t = context.pharmaTokens;
            final compactStyle = PharmaComponentTheme.outlined(
              t,
              Theme.of(context).colorScheme,
              compact: true,
            );
            final enabled =
                listState.items.isNotEmpty && !reportState.isSubmitting;
            return OutlinedButton.icon(
              style: compactStyle,
              onPressed: !enabled
                  ? null
                  : () async {
                      final selected =
                          await showEnterpriseDropdownMenuFrom<String>(
                        context: context,
                        anchorContext: anchorContext,
                        items: const [
                          EnterpriseDropdownItem(
                            value: 'pdf',
                            label: 'Exportar PDF',
                            icon: Icons.picture_as_pdf_outlined,
                          ),
                          EnterpriseDropdownItem(
                            value: 'csv',
                            label: 'Exportar CSV',
                            icon: Icons.table_chart_outlined,
                          ),
                        ],
                      );
                      if (selected == 'pdf') {
                        reportController.downloadPdf(
                          path: ReportPaths.invoices,
                          queryParameters: reportQuery,
                        );
                      } else if (selected == 'csv') {
                        reportController.exportCsv(
                          path: ReportPaths.invoices,
                          queryParameters: reportQuery,
                        );
                      }
                    },
              icon: Icon(Icons.download_outlined, size: t.iconSm),
              label: Text(
                'Exportar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            );
          },
        ),
      ],
      child: InvoicesBody(
        searchController: _searchController,
        listState: listState,
        detailState: detailState,
        onView: _openDetails,
        onCancel: _confirmCancelInvoice,
        onPrint: _printInvoice,
      ),
    ),
    );
  }

  Future<void> _openDetails(InvoiceSummary invoice) async {
    ref.read(invoiceDetailProvider.notifier).open(invoice);

    await AdaptiveNavigator.openPanel<void>(
      context: context,
      routeSettings: RouteSettings(name: '/faturas/${invoice.id}'),
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return InvoiceDetailScreen(
            invoice: invoice,
            onCancel: invoice.isCancelled
                ? null
                : () {
                    AdaptiveNavigator.close(detailContext);
                    _confirmCancelInvoice(invoice);
                  },
          );
        }
        return InvoiceDetailPanel(
          invoice: invoice,
          onClose: () => AdaptiveNavigator.close(detailContext),
          onCancel: invoice.isCancelled
              ? null
              : () {
                  AdaptiveNavigator.close(detailContext);
                  _confirmCancelInvoice(invoice);
                },
        );
      },
    );

    ref.read(invoiceDetailProvider.notifier).close();
  }

  Future<void> _printInvoice(InvoiceSummary invoice) async {
    try {
      await ref.read(invoiceActionProvider.notifier).printReceipt(
            invoiceId: invoice.id,
            tipo: invoice.tipo,
            previewContext: context,
          );
      if (!mounted) return;
      PharmaFeedback.success(
        context,
        invoice.isThermalReceipt
            ? 'Recibo 80mm enviado para impressão.'
            : 'PDF A4 pronto para imprimir.',
      );
    } catch (e) {
      if (!mounted) return;
      final message =
          ref.read(invoiceActionProvider).errorMessage ?? e.toString();
      await PharmaFeedback.criticalError(
        context: context,
        title: 'Falha na impressão',
        message: message,
      );
    }
  }

  Future<void> _confirmCancelInvoice(InvoiceSummary invoice) async {
    if (invoice.isCancelled) {
      return;
    }

    final result = await showCancelInvoiceDialog(context, invoice: invoice);

    if (!mounted || result == null) {
      return;
    }

    try {
      await ref
          .read(invoiceActionProvider.notifier)
          .cancelInvoice(
            invoiceId: invoice.id,
            motivo: result.motivo,
            observacoes: result.observacoes,
          );
    } catch (_) {
      // A mensagem ja e tratada pelo listener do provider.
    }
  }

  Map<String, dynamic> _buildReportQuery(InvoiceQuery query) {
    String? formatDate(DateTime? value) {
      if (value == null) {
        return null;
      }
      final year = value.year.toString().padLeft(4, '0');
      final month = value.month.toString().padLeft(2, '0');
      final day = value.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    return <String, dynamic>{
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.clienteId != null) 'clienteId': query.clienteId,
      if (query.status != null) 'status': query.status,
      if (query.dateFrom != null) 'dateFrom': formatDate(query.dateFrom),
      if (query.dateTo != null) 'dateTo': formatDate(query.dateTo),
      if (query.terminalId != null) 'terminalId': query.terminalId,
      if (query.userId != null) 'userId': query.userId,
    };
  }
}

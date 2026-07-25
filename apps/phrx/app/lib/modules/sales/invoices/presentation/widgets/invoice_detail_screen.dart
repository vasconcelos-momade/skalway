import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';

import '../../domain/entities/invoice_detail.dart';
import '../../domain/entities/invoice_summary.dart';
import '../providers/invoice_action_provider.dart';
import '../providers/invoice_detail_provider.dart';
import 'invoice_detail_widgets.dart';
import 'invoice_formatters.dart';
import 'invoice_status_badge.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoice, this.onCancel});

  final InvoiceSummary invoice;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final actionState = ref.watch(invoiceActionProvider);
    final detailState = ref.watch(invoiceDetailProvider);
    final detail = detailState.detail?.id == invoice.id
        ? detailState.detail
        : null;
    final isCancelling =
        actionState.isSubmitting && actionState.activeInvoiceId == invoice.id;
    final canCancel = detail?.permissions.canCancel ?? !invoice.isCancelled;

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(invoice.numero),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.lg),
          child: _InvoiceDetailScaffold(
            invoice: invoice,
            detail: detail,
            isLoading: detailState.isLoading && detail == null,
            errorMessage: detailState.errorMessage,
            isCancelling: isCancelling,
            canCancel: canCancel,
            onRetry: () => ref.read(invoiceDetailProvider.notifier).refresh(),
            onCancel: isCancelling || !canCancel ? null : onCancel,
          ),
        ),
      ),
    );
  }
}

class InvoiceDetailPanel extends ConsumerWidget {
  const InvoiceDetailPanel({
    super.key,
    required this.invoice,
    required this.onClose,
    this.onCancel,
  });

  final InvoiceSummary invoice;
  final VoidCallback onClose;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final actionState = ref.watch(invoiceActionProvider);
    final detailState = ref.watch(invoiceDetailProvider);
    final detail = detailState.detail?.id == invoice.id
        ? detailState.detail
        : null;
    final isCancelling =
        actionState.isSubmitting && actionState.activeInvoiceId == invoice.id;
    final canCancel = detail?.permissions.canCancel ?? !invoice.isCancelled;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: _InvoiceDetailScaffold(
          invoice: invoice,
          detail: detail,
          isLoading: detailState.isLoading && detail == null,
          errorMessage: detailState.errorMessage,
          isCancelling: isCancelling,
          canCancel: canCancel,
          headerTrailing: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          actionsAsColumn: isMobile,
          onRetry: () => ref.read(invoiceDetailProvider.notifier).refresh(),
          onCancel: isCancelling || !canCancel ? null : onCancel,
        ),
      ),
    );
  }
}

class _InvoiceDetailScaffold extends StatelessWidget {
  const _InvoiceDetailScaffold({
    required this.invoice,
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
    required this.isCancelling,
    required this.canCancel,
    required this.onRetry,
    this.onCancel,
    this.headerTrailing,
    this.actionsAsColumn = true,
  });

  final InvoiceSummary invoice;
  final InvoiceDetail? detail;
  final bool isLoading;
  final String? errorMessage;
  final bool isCancelling;
  final bool canCancel;
  final VoidCallback onRetry;
  final VoidCallback? onCancel;
  final Widget? headerTrailing;
  final bool actionsAsColumn;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final status = detail?.estado ?? invoice.estado;
    final customerName =
        detail?.cliente?.nome ?? invoice.cliente?.nome ?? 'Consumidor final';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerTrailing != null)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.numero,
                      style: Theme.of(
                        context,
                      ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                    ),
                    SizedBox(height: s.xs),
                    Text(
                      customerName,
                      style: Theme.of(
                        context,
                      ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              headerTrailing!,
            ],
          )
        else
          Text(
            customerName,
            style: Theme.of(
              context,
            ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
          ),
        SizedBox(height: s.md),
        InvoiceStatusBadge(status: status),
        SizedBox(height: s.lg),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  _DetailLoadingState(invoice: invoice)
                else if (detail != null)
                  _LoadedInvoiceDetail(detail: detail!)
                else
                  _DetailErrorState(
                    message:
                        errorMessage ?? 'Falha ao carregar detalhe da fatura.',
                    onRetry: onRetry,
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: s.lg),
        _DetailActions(
          invoice: invoice,
          detailTipo: detail?.tipo,
          canExportPdf: detail?.permissions.canExportPdf ?? !invoice.isThermalReceipt,
          actionsAsColumn: actionsAsColumn,
          isCancelling: isCancelling,
          canCancel: canCancel,
          onCancel: onCancel,
        ),
      ],
    );
  }
}

class _LoadedInvoiceDetail extends StatelessWidget {
  const _LoadedInvoiceDetail({required this.detail});

  final InvoiceDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSection(
          title: 'Dados da fatura',
          children: [
            DetailRow(label: 'Número', value: detail.numero),
            DetailRow(label: 'Série', value: detail.serie ?? '-'),
            DetailRow(label: 'Tipo', value: detail.tipo),
            DetailRow(label: 'Data', value: formatDateTime(detail.createdAt)),
            DetailRow(
              label: 'Actualizada em',
              value: formatDateTime(detail.updatedAt),
            ),
            DetailRow(
              label: 'Cancelada em',
              value: formatDateTime(detail.cancelledAt),
            ),
            DetailRow(
              label: 'Método de pagamento',
              value: detail.tipoPagamento ?? '-',
            ),
            DetailRow(
              label: 'Operação fiscal',
              value: detail.tipoOperacao ?? '-',
            ),
            DetailRow(
              label: 'Terminal',
              value: detail.terminal?.codigo ?? detail.terminal?.nome ?? '-',
            ),
            DetailRow(label: 'Operador', value: detail.user?.name ?? '-'),
            DetailRow(
              label: 'Responsável anulação',
              value:
                  detail.cancelledBy?.name ??
                  detail.anulacao?.user?.name ??
                  '-',
            ),
          ],
        ),
        SizedBox(height: s.lg),
        DetailSection(
          title: 'Totais',
          children: [
            DetailRow(label: 'Subtotal', value: formatMoney(detail.subtotal)),
            DetailRow(label: 'Desconto', value: formatMoney(detail.desconto)),
            DetailRow(label: 'IVA', value: formatMoney(detail.ivaTotal)),
            DetailRow(label: 'Total', value: formatMoney(detail.total)),
            DetailRow(
              label: 'Valor recebido',
              value: detail.valorRecebido == null
                  ? '-'
                  : formatMoney(detail.valorRecebido!),
            ),
            DetailRow(label: 'Troco', value: formatMoney(detail.troco)),
            DetailRow(label: 'Moeda', value: detail.moeda),
          ],
        ),
        SizedBox(height: s.lg),
        DetailSection(
          title: 'Itens',
          children: [
            DetailRow(
              label: 'Linhas registadas',
              value: '${detail.summary.itemCount}',
            ),
            SizedBox(height: s.sm),
            ...detail.items.map((item) => _DetailItemTile(item: item)),
          ],
        ),
        SizedBox(height: s.lg),
        DetailSection(
          title: 'Pagamentos',
          children: [
            DetailRow(
              label: 'Pagamentos',
              value: '${detail.summary.paymentCount}',
            ),
            SizedBox(height: s.sm),
            if (detail.payments.isEmpty)
              const DetailHint(
                text: 'Sem pagamentos registados para esta fatura.',
              )
            else
              ...detail.payments.map(
                (payment) => _DetailPaymentTile(payment: payment),
              ),
          ],
        ),
        if (detail.anulacao != null) ...[
          SizedBox(height: s.lg),
          DetailSection(
            title: 'Anulação',
            children: [
              DetailRow(label: 'Motivo', value: detail.anulacao!.motivo),
              DetailRow(
                label: 'Observações',
                value: detail.anulacao!.observacoes ?? '-',
              ),
              DetailRow(
                label: 'Data',
                value: formatDateTime(detail.anulacao!.createdAt),
              ),
              DetailRow(
                label: 'Utilizador',
                value: detail.anulacao!.user?.name ?? '-',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DetailItemTile extends StatelessWidget {
  const _DetailItemTile({required this.item});

  final InvoiceDetailItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final hasLotes = item.lotes.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: s.sm),
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: t.bgSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.descricao,
            style: Theme.of(
              context,
            ).textTheme.erpBodyStrong.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: s.xs),
          Wrap(
            spacing: s.sm,
            runSpacing: s.xs,
            children: [
              _InlineMeta(label: 'Tipo', value: item.tipo.toUpperCase()),
              _InlineMeta(
                label: 'Qtd',
                value: item.quantidade.toStringAsFixed(
                  item.quantidade % 1 == 0 ? 0 : 2,
                ),
              ),
              _InlineMeta(label: 'Unit.', value: formatMoney(item.precoUnit)),
              _InlineMeta(
                label: 'IVA',
                value:
                    '${item.taxaAplicada.toStringAsFixed(item.taxaAplicada % 1 == 0 ? 0 : 2)}%',
              ),
              _InlineMeta(label: 'Total', value: formatMoney(item.total)),
            ],
          ),
          if (item.codigoRegraFiscal != null || item.motivoIsencao != null) ...[
            SizedBox(height: s.xs),
            Text(
              [
                if (item.codigoRegraFiscal != null)
                  'Regra: ${item.codigoRegraFiscal}',
                if (item.motivoIsencao != null)
                  'Motivo isenção: ${item.motivoIsencao}',
              ].join(' | '),
              style: Theme.of(
                context,
              ).textTheme.erpCaption.copyWith(color: t.textMuted),
            ),
          ],
          if (hasLotes) ...[
            SizedBox(height: s.sm),
            ...item.lotes.map(
              (lote) => Padding(
                padding: EdgeInsets.only(bottom: s.xs),
                child: Text(
                  'Lote ${lote.codigo} · ${lote.quantidade.toStringAsFixed(lote.quantidade % 1 == 0 ? 0 : 2)} un. · FEFO ${lote.ordemFefo}',
                  style: Theme.of(
                    context,
                  ).textTheme.erpCaption.copyWith(color: t.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailPaymentTile extends StatelessWidget {
  const _DetailPaymentTile({required this.payment});

  final InvoiceDetailPayment payment;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: s.sm),
      padding: EdgeInsets.all(s.sm),
      decoration: BoxDecoration(
        color: t.bgSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payment.metodo,
            style: Theme.of(
              context,
            ).textTheme.erpBodyStrong.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: s.xs),
          Wrap(
            spacing: s.sm,
            runSpacing: s.xs,
            children: [
              _InlineMeta(label: 'Valor', value: formatMoney(payment.valor)),
              _InlineMeta(label: 'Estado', value: payment.status),
              _InlineMeta(
                label: 'Data',
                value: formatDateTime(payment.createdAt),
              ),
            ],
          ),
          if (payment.referencia != null) ...[
            SizedBox(height: s.xs),
            Text(
              'Referência: ${payment.referencia}',
              style: Theme.of(
                context,
              ).textTheme.erpCaption.copyWith(color: t.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailActions extends ConsumerWidget {
  const _DetailActions({
    required this.invoice,
    required this.actionsAsColumn,
    required this.isCancelling,
    required this.canCancel,
    this.detailTipo,
    this.canExportPdf = true,
    this.onCancel,
  });

  final InvoiceSummary invoice;
  final String? detailTipo;
  final bool canExportPdf;
  final bool actionsAsColumn;
  final bool isCancelling;
  final bool canCancel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final actionState = ref.watch(invoiceActionProvider);
    final controller = ref.read(invoiceActionProvider.notifier);
    final isBusy =
        actionState.isSubmitting && actionState.activeInvoiceId == invoice.id;
    final isPrinting = isBusy && actionState.lastAction == 'print';
    final isShowing = isBusy && actionState.lastAction == 'show';
    final isExportingPdf = isBusy && actionState.lastAction == 'pdf';
    final tipo = (detailTipo ?? invoice.tipo).toUpperCase();
    final isThermal = tipo == 'FR';

    Future<void> showDocument() async {
      try {
        await controller.showDocument(
          invoiceId: invoice.id,
          tipo: tipo,
          previewContext: context,
        );
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.success(
          context,
          isThermal
              ? 'PDF do recibo 80mm disponibilizado.'
              : 'PDF A4 disponibilizado.',
        );
      } on ApiFailure catch (e) {
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.error(context, e.message);
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.error(
          context,
          isThermal
              ? 'Não foi possível mostrar o recibo 80mm.'
              : 'Não foi possível abrir o PDF A4.',
        );
      }
    }

    Future<void> exportPdf() async {
      try {
        await controller.exportPdf(invoiceId: invoice.id, tipo: tipo);
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.success(
          context,
          'PDF A4 da fatura disponibilizado com sucesso.',
        );
      } on ApiFailure catch (e) {
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.error(context, e.message);
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.error(
          context,
          'Não foi possível exportar o PDF da fatura.',
        );
      }
    }

    Future<void> printReceipt() async {
      try {
        await controller.printReceipt(
          invoiceId: invoice.id,
          tipo: tipo,
          previewContext: context,
        );
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.success(
          context,
          isThermal
              ? 'Impressão térmica 80mm preparada.'
              : 'PDF A4 pronto para imprimir.',
        );
      } on ApiFailure catch (e) {
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.error(context, e.message);
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        PharmaFeedback.error(
          context,
          isThermal
              ? 'Não foi possível imprimir o recibo 80mm.'
              : 'Não foi possível preparar o PDF A4.',
        );
      }
    }

    final children = <Widget>[
      OutlinedButton.icon(
        onPressed: isBusy ? null : showDocument,
        icon: isShowing
            ? const PharmaButtonLoader()
            : Icon(
                isThermal
                    ? Icons.receipt_long_outlined
                    : Icons.visibility_outlined,
              ),
        label: Text(isThermal ? 'Ver PDF 80mm' : 'Ver A4'),
      ),
      OutlinedButton.icon(
        onPressed: isBusy ? null : printReceipt,
        icon: isPrinting
            ? const PharmaButtonLoader()
            : const Icon(Icons.print_outlined),
        label: Text(isThermal ? 'Imprimir 80mm' : 'Imprimir A4'),
      ),
      if (!isThermal && canExportPdf)
        OutlinedButton.icon(
          onPressed: isBusy ? null : exportPdf,
          icon: isExportingPdf
              ? const PharmaButtonLoader()
              : const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Exportar PDF'),
        ),
      FilledButton.icon(
        onPressed: isBusy || isCancelling || !canCancel ? null : onCancel,
        icon: isCancelling
            ? const PharmaButtonLoader()
            : const Icon(Icons.block_rounded),
        label: const Text('Cancelar fatura'),
      ),
    ];

    if (actionsAsColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: s.sm),
            children[i],
          ],
        ],
      );
    }

    return Wrap(spacing: s.sm, runSpacing: s.sm, children: children);
  }
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState({required this.invoice});

  final InvoiceSummary invoice;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSection(
          title: 'Dados da fatura',
          children: [
            DetailRow(label: 'Número', value: invoice.numero),
            DetailRow(
              label: 'Cliente',
              value: invoice.cliente?.nome ?? 'Consumidor final',
            ),
            const DetailHint(text: 'A carregar detalhe completo da fatura...'),
          ],
        ),
        SizedBox(height: s.lg),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return DetailSection(
      title: 'Detalhe indisponível',
      children: [
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.erpBodySecondary.copyWith(color: t.textPrimary),
        ),
        SizedBox(height: s.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.erpCaption.copyWith(color: t.textMuted),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: Theme.of(
              context,
            ).textTheme.erpBodySecondary.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    );
  }
}

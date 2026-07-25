import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../platform/files/platform_file_delivery.dart';
import '../../../../../platform/printing/thermal/printer_connection.dart';
import '../../../../../platform/printing/thermal/thermal_printer_service.dart';
import '../../../../settings/services/default_printer_service.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/invoice_document_mode.dart';
import '../../services/invoice_cache_policy.dart';
import '../widgets/thermal_receipt_preview_dialog.dart';
import 'invoice_detail_provider.dart';
import 'invoice_list_provider.dart';

class InvoiceActionState {
  const InvoiceActionState({
    this.isSubmitting = false,
    this.activeInvoiceId,
    this.errorMessage,
    this.lastAction,
  });

  final bool isSubmitting;
  final String? activeInvoiceId;
  final String? errorMessage;
  final String? lastAction;

  InvoiceActionState copyWith({
    bool? isSubmitting,
    String? activeInvoiceId,
    String? errorMessage,
    String? lastAction,
    bool clearError = false,
    bool clearActiveInvoice = false,
  }) {
    return InvoiceActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeInvoiceId: clearActiveInvoice
          ? null
          : (activeInvoiceId ?? this.activeInvoiceId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class InvoiceActionController extends Notifier<InvoiceActionState> {
  @override
  InvoiceActionState build() => const InvoiceActionState();

  Future<String> _resolveTipo({
    required String invoiceId,
    String? tipo,
  }) async {
    if (tipo != null && tipo.trim().isNotEmpty) {
      return tipo.trim().toUpperCase();
    }
    final detail =
        await ref.read(invoiceRepositoryProvider).getInvoiceDetail(invoiceId);
    return detail.tipo.trim().toUpperCase();
  }

  Future<void> _openInvoicePdf(String invoiceId) async {
    final document = await ref.read(invoiceRepositoryProvider).getInvoicePdf(
          invoiceId,
        );

    await PlatformFileDelivery.openBytes(
      bytes: document.bytes,
      fileName: document.fileName,
      contentType: document.contentType,
    );
  }

  Future<PrinterConnection?> _readDefaultPrinterConnection() {
    return ref.read(defaultPrinterServiceProvider).resolveConnection();
  }

  /// Mostra o documento: FR → PDF 80mm; FT → PDF A4.
  Future<void> showDocument({
    required String invoiceId,
    String? tipo,
    BuildContext? previewContext,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeInvoiceId: invoiceId,
      lastAction: 'show',
      clearError: true,
    );

    try {
      // Ambos os tipos usam /pdf (FR=80mm, FT=A4) — abre no visualizador.
      await _openInvoicePdf(invoiceId);

      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Exportar/abrir PDF — FR = 80mm; FT = A4.
  Future<void> exportPdf({
    required String invoiceId,
    String? tipo,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeInvoiceId: invoiceId,
      lastAction: 'pdf',
      clearError: true,
    );

    try {
      await _openInvoicePdf(invoiceId);

      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Imprime: FR → ESC/POS 80mm; FT → abre PDF A4 (impressão sistema).
  Future<void> printReceipt({
    required String invoiceId,
    String? tipo,
    BuildContext? previewContext,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeInvoiceId: invoiceId,
      lastAction: 'print',
      clearError: true,
    );

    try {
      final resolvedTipo = await _resolveTipo(invoiceId: invoiceId, tipo: tipo);

      if (!isThermalReceiptTipo(resolvedTipo)) {
        await _openInvoicePdf(invoiceId);
        state = state.copyWith(
          isSubmitting: false,
          clearActiveInvoice: true,
          clearError: true,
        );
        return;
      }

      final artifact =
          await ref.read(invoiceRepositoryProvider).getInvoicePrintArtifact(
                invoiceId,
              );

      final connection = await _readDefaultPrinterConnection();
      if (connection == null) {
        if (previewContext != null && previewContext.mounted) {
          await showThermalReceiptPreview(
            previewContext,
            title: 'Recibo 80mm (sem impressora)',
            previewText: decodeEscPosPreview(artifact.bytes),
          );
        } else {
          await ThermalPrinterService.downloadFallback(
            bytes: artifact.bytes,
            fileName: artifact.fileName,
            contentType: artifact.contentType,
          );
        }
      } else {
        try {
          await ThermalPrinterService.printReceipt(
            bytes: artifact.bytes,
            fileName: artifact.fileName,
            contentType: artifact.contentType,
            connection: connection,
          );
        } catch (_) {
          await ThermalPrinterService.downloadFallback(
            bytes: artifact.bytes,
            fileName: artifact.fileName,
            contentType: artifact.contentType,
          );
        }
      }

      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeInvoiceId: invoiceId,
      lastAction: 'cancel',
      clearError: true,
    );

    try {
      await ref.read(invoiceRepositoryProvider).cancelInvoice(
            invoiceId: invoiceId,
            motivo: motivo,
            observacoes: observacoes,
          );
      invalidateInvoiceListCache();
      ref.invalidate(invoiceListProvider);
      unawaited(ref.read(invoiceListProvider.notifier).refresh());

      ref.read(invoiceDetailProvider.notifier).markCancelled(invoiceId: invoiceId);

      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveInvoice: true,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final invoiceActionProvider =
    NotifierProvider<InvoiceActionController, InvoiceActionState>(
  InvoiceActionController.new,
);

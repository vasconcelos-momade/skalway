import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/entities/invoice_detail.dart';
import '../../domain/entities/invoice_summary.dart';

class InvoiceDetailState {
  const InvoiceDetailState({
    this.selected,
    this.detail,
    this.isLoading = false,
    this.errorMessage,
  });

  final InvoiceSummary? selected;
  final InvoiceDetail? detail;
  final bool isLoading;
  final String? errorMessage;

  bool get hasSelection => selected != null;
  bool get hasDetail => detail != null;

  InvoiceDetailState copyWith({
    InvoiceSummary? selected,
    InvoiceDetail? detail,
    bool? isLoading,
    String? errorMessage,
    bool clearSelection = false,
    bool clearDetail = false,
    bool clearError = false,
  }) {
    return InvoiceDetailState(
      selected: clearSelection ? null : (selected ?? this.selected),
      detail: clearDetail ? null : (detail ?? this.detail),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InvoiceDetailController extends Notifier<InvoiceDetailState> {
  int _requestId = 0;

  @override
  InvoiceDetailState build() => const InvoiceDetailState();

  Future<void> open(InvoiceSummary invoice) async {
    final requestId = ++_requestId;
    state = state.copyWith(
      selected: invoice,
      isLoading: true,
      clearDetail: true,
      clearError: true,
    );

    try {
      final detail =
          await ref.read(invoiceRepositoryProvider).getInvoiceDetail(invoice.id);
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        selected: invoice,
        detail: detail,
        isLoading: false,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        selected: invoice,
        isLoading: false,
        errorMessage: e.message,
        clearDetail: true,
      );
    } catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        selected: invoice,
        isLoading: false,
        errorMessage: e.toString(),
        clearDetail: true,
      );
    }
  }

  Future<void> refresh() async {
    final selected = state.selected;
    if (selected == null) {
      return;
    }
    await open(selected);
  }

  void markCancelled({
    required String invoiceId,
  }) {
    final selected = state.selected;
    final detail = state.detail;
    if (selected?.id != invoiceId || detail?.id != invoiceId) {
      return;
    }

    final now = DateTime.now();
    state = state.copyWith(
      selected: selected!.copyWith(
        estado: 'ANULADA',
        cancelledAt: now,
      ),
      detail: detail!.copyWith(
        estado: 'ANULADA',
        cancelledAt: now,
        permissions: detail.permissions.copyWith(canCancel: false),
      ),
    );
  }

  void close() {
    _requestId++;
    state = state.copyWith(
      clearSelection: true,
      clearDetail: true,
      isLoading: false,
      clearError: true,
    );
  }
}

final invoiceDetailProvider =
    NotifierProvider<InvoiceDetailController, InvoiceDetailState>(
  InvoiceDetailController.new,
);

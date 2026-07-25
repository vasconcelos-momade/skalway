import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/pdv_catalog_cache_policy.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../customers/data/repositories/customer_repository_impl.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../../invoices/services/invoice_cache_policy.dart';
import '../../../invoices/presentation/providers/invoice_list_provider.dart';
import '../../data/repositories/pdv_cart_repository_impl.dart';
import '../../domain/entities/pdv_checkout.dart';
import 'caixa_sessao_provider.dart';
import 'pdv_cart_provider.dart';

class PdvCheckoutState {
  const PdvCheckoutState({
    this.isSubmitting = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String? errorMessage;

  PdvCheckoutState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PdvCheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PdvCheckoutController extends Notifier<PdvCheckoutState> {
  @override
  PdvCheckoutState build() => const PdvCheckoutState();

  Future<PdvCheckoutResult> finalizarVenda({
    required PdvPaymentMethod metodoPagamento,
    PdvCheckoutPatient? paciente,
    double? valorRecebido,
    String? nomeClienteDigitado,
    bool criarClienteSeNecessario = false,
  }) async {
    final sessao = ref.read(caixaSessaoProvider).sessaoAtual;
    final cartState = ref.read(pdvCartProvider);
    final terminalId = sessao?.terminalId;
    final idempotencyKey = cartState.cart.idempotencyKey;

    if (sessao == null || terminalId == null || terminalId.isEmpty) {
      throw const ApiFailure('Sessão de caixa sem terminal associado.');
    }
    if (idempotencyKey == null || idempotencyKey.isEmpty) {
      throw const ApiFailure('Carrinho PDV sem chave de sincronização.');
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      var clienteId = cartState.hasSelectedCliente
          ? cartState.selectedClienteId
          : null;
      final nomeDigitado = nomeClienteDigitado?.trim() ?? '';

      if (
        clienteId == null &&
        criarClienteSeNecessario &&
        nomeDigitado.isNotEmpty &&
        nomeDigitado.toLowerCase() !=
            PdvCartState.defaultClienteLabel.toLowerCase()
      ) {
        final created = await ref.read(customerRepositoryProvider).createCustomer(
              CustomerFormPayload(
                nome: nomeDigitado,
                tipo: 'PACIENTE',
                temPrescricao: cartState.requiresPatientDetails,
              ),
            );
        clienteId = created.id;
      }

      final result = await ref.read(pdvCartRepositoryProvider).finalizarVenda(
            terminalId: terminalId,
            idempotencyKey: idempotencyKey,
            metodoPagamento: metodoPagamento,
            clienteId: clienteId,
            paciente: paciente,
            valorRecebido: valorRecebido,
          );
      if (result.cartReset) {
        ref
            .read(pdvCartProvider.notifier)
            .applyCheckoutReset(result.nextCartIdempotencyKey);
      }
      invalidatePdvProductCatalogCache();
      ref.invalidate(productListProvider);
      invalidateInvoiceListCache();
      ref.invalidate(invoiceListProvider);
      // Garante atualização imediata: evita qualquer chance de ficar preso em cache/estado.
      unawaited(ref.read(invoiceListProvider.notifier).refresh());
      state = state.copyWith(isSubmitting: false, clearError: true);
      return result;
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final pdvCheckoutProvider =
    NotifierProvider<PdvCheckoutController, PdvCheckoutState>(
  PdvCheckoutController.new,
);

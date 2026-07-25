import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../app/providers/app_theme_mode_provider.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../data/repositories/pdv_cart_repository_impl.dart';
import '../../domain/repositories/pdv_cart_repository.dart';
import '../../domain/entities/pdv_cart.dart';
import '../../domain/entities/pdv_cart_line.dart';
import '../../domain/entities/pdv_service.dart';
import '../../services/pdv_session_service.dart';
import 'caixa_sessao_provider.dart';

class PdvCartState {
  const PdvCartState({
    this.cart = const PdvCart(),
    this.isLoading = false,
    this.isMutating = false,
    this.busyLineId,
    this.selectedClienteId,
    this.selectedClienteNome,
  });

  final PdvCart cart;
  final bool isLoading;
  final bool isMutating;
  final String? busyLineId;

  /// Cliente cadastrado seleccionado. Null = venda rápida (Consumidor Final no backend).
  final String? selectedClienteId;
  final String? selectedClienteNome;

  List<PdvCartLine> get lines => cart.lines;

  bool get isEmpty => lines.isEmpty;

  String get taxLabel => cart.taxLabel;

  double get subtotal => cart.subtotal;
  double get tax => cart.tax;
  double get discount => cart.discount;
  double get total => cart.total;
  bool get requiresPatientDetails => cart.requiresPatientDetails;

  /// Rótulo mostrado na UI quando nenhum cliente cadastrado foi escolhido.
  static const defaultClienteLabel = 'Consumidor Final';

  String get displayClienteNome =>
      (selectedClienteNome != null && selectedClienteNome!.trim().isNotEmpty)
          ? selectedClienteNome!.trim()
          : defaultClienteLabel;

  bool get hasSelectedCliente =>
      selectedClienteId != null && selectedClienteId!.trim().isNotEmpty;

  bool isLineBusy(String lineId) => isMutating && busyLineId == lineId;

  PdvCartState copyWith({
    PdvCart? cart,
    bool? isLoading,
    bool? isMutating,
    String? busyLineId,
    bool clearBusyLineId = false,
    String? selectedClienteId,
    String? selectedClienteNome,
    bool clearSelectedCliente = false,
  }) {
    return PdvCartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      busyLineId: clearBusyLineId ? null : (busyLineId ?? this.busyLineId),
      selectedClienteId: clearSelectedCliente
          ? null
          : (selectedClienteId ?? this.selectedClienteId),
      selectedClienteNome: clearSelectedCliente
          ? null
          : (selectedClienteNome ?? this.selectedClienteNome),
    );
  }

  static const initial = PdvCartState();
}

class PdvCartController extends Notifier<PdvCartState> {
  bool _didLoadForSession = false;
  String? _activeSessionId;

  @override
  PdvCartState build() {
    ref.listen(caixaSessaoProvider, (previous, next) {
      if (previous?.hasSessaoAberta == true && !next.hasSessaoAberta) {
        _clearPersistedCartKey();
        state = PdvCartState.initial;
        _didLoadForSession = false;
        _activeSessionId = null;
        return;
      }
      _maybeLoadFromServer();
    });

    ref.listen(authSessionProvider, (_, _) => _maybeLoadFromServer());

    _maybeLoadFromServer();
    return PdvCartState.initial;
  }

  bool get _canSyncCart {
    final caixa = ref.read(caixaSessaoProvider);
    final auth = ref.read(authSessionProvider);
    final userId = auth.session?.user.id;
    return caixa.hasSessaoAberta &&
        caixa.isInitialized &&
        !auth.isBootstrapping &&
        userId != null &&
        userId.isNotEmpty;
  }

  void _maybeLoadFromServer() {
    if (!_canSyncCart || _didLoadForSession || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearBusyLineId: true);
    Future.microtask(loadFromServer);
  }

  String? _resolveIdempotencyKey() {
    final sessao = ref.read(caixaSessaoProvider).sessaoAtual;
    if (sessao == null) {
      return null;
    }

    final userId = sessao.userId;
    if (userId.isEmpty) {
      return null;
    }

    _activeSessionId = sessao.id;

    final inMemoryKey = state.cart.idempotencyKey;
    if (inMemoryKey != null && inMemoryKey.isNotEmpty) {
      return inMemoryKey;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final persistedKey = prefs.getString(
      PdvSessionService.cartIdempotencyStorageKey(userId, sessao.id),
    );
    if (persistedKey != null && persistedKey.isNotEmpty) {
      return persistedKey;
    }

    return PdvSessionService.defaultCartIdempotencyKey(userId, sessao.id);
  }

  void _persistIdempotencyKey(String key) {
    final sessaoId = _activeSessionId ?? ref.read(caixaSessaoProvider).sessaoAtual?.id;
    final userId = ref.read(caixaSessaoProvider).sessaoAtual?.userId;
    if (userId == null || userId.isEmpty || sessaoId == null || sessaoId.isEmpty) {
      return;
    }

    ref.read(sharedPreferencesProvider).setString(
          PdvSessionService.cartIdempotencyStorageKey(userId, sessaoId),
          key,
        );
  }

  void _clearPersistedCartKey() {
    final sessaoId = _activeSessionId ?? ref.read(caixaSessaoProvider).sessaoAtual?.id;
    final userId = ref.read(caixaSessaoProvider).sessaoAtual?.userId;
    if (userId == null || userId.isEmpty || sessaoId == null || sessaoId.isEmpty) {
      return;
    }

    ref.read(sharedPreferencesProvider).remove(
          PdvSessionService.cartIdempotencyStorageKey(userId, sessaoId),
        );
  }

  ({String userId, String idempotencyKey})? _mutationContext() {
    if (!ref.read(caixaSessaoProvider).hasSessaoAberta) {
      return null;
    }

    final sessao = ref.read(caixaSessaoProvider).sessaoAtual;
    if (sessao == null || sessao.userId.isEmpty) {
      return null;
    }

    final key = _resolveIdempotencyKey();
    if (key == null || key.isEmpty) {
      return null;
    }

    return (userId: sessao.userId, idempotencyKey: key);
  }

  void _applyCart(PdvCart cart) {
    final key = cart.idempotencyKey;
    if (key != null && key.isNotEmpty) {
      _persistIdempotencyKey(key);
    }

    state = state.copyWith(
      cart: cart,
      isLoading: false,
      isMutating: false,
      clearBusyLineId: true,
    );
  }

  Future<void> loadFromServer() async {
    final ctx = _mutationContext();
    if (ctx == null) {
      state = state.copyWith(isLoading: false, clearBusyLineId: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearBusyLineId: true);

    try {
      final cart = await ref.read(pdvCartRepositoryProvider).getCart(
            userId: ctx.userId,
            idempotencyKey: ctx.idempotencyKey,
          );
      _didLoadForSession = true;
      _applyCart(cart);
    } on ApiFailure {
      state = state.copyWith(isLoading: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isLoading: false, clearBusyLineId: true);
      rethrow;
    }
  }

  /// Garante recarga do carrinho após hot reload ou reentrada na página PDV.
  void ensureLoaded() {
    _didLoadForSession = false;
    state = state.copyWith(isLoading: false, clearBusyLineId: true);
    _maybeLoadFromServer();
  }

  Future<bool> addProduct(Product product) async {
    final ctx = _mutationContext();
    if (ctx == null) {
      return false;
    }

    final lineId = 'produto:${product.id}';
    state = state.copyWith(isMutating: true, busyLineId: lineId);

    try {
      final cart = await ref.read(pdvCartRepositoryProvider).addItem(
            userId: ctx.userId,
            idempotencyKey: ctx.idempotencyKey,
            product: product,
          );
      _applyCart(cart);
      return true;
    } on ApiFailure {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    }
  }

  Future<bool> addService(PdvService service) async {
    final ctx = _mutationContext();
    if (ctx == null) {
      return false;
    }

    final lineId = 'servico:${service.id}';
    state = state.copyWith(isMutating: true, busyLineId: lineId);

    try {
      final cart = await ref.read(pdvCartRepositoryProvider).addService(
            userId: ctx.userId,
            idempotencyKey: ctx.idempotencyKey,
            service: service,
          );
      _applyCart(cart);
      return true;
    } on ApiFailure {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    }
  }

  Future<bool> incrementLine(PdvCartLine line) async {
    if (!line.canMutateViaApi) {
      throw const ApiFailure('Item não sincronizado com o servidor.');
    }
    return _mutateItem(line, (repo, ctx) => repo.incrementItem(
          userId: ctx.userId,
          idempotencyKey: ctx.idempotencyKey,
          itemId: line.faturaItemId!,
        ));
  }

  Future<bool> decrementLine(PdvCartLine line) async {
    if (!line.canMutateViaApi) {
      throw const ApiFailure('Item não sincronizado com o servidor.');
    }
    return _mutateItem(line, (repo, ctx) => repo.decrementItem(
          userId: ctx.userId,
          idempotencyKey: ctx.idempotencyKey,
          itemId: line.faturaItemId!,
        ));
  }

  Future<bool> removeLine(PdvCartLine line) async {
    if (!line.canMutateViaApi) {
      throw const ApiFailure('Item não sincronizado com o servidor.');
    }
    return _mutateItem(line, (repo, ctx) => repo.removeItem(
          userId: ctx.userId,
          idempotencyKey: ctx.idempotencyKey,
          itemId: line.faturaItemId!,
        ));
  }

  Future<bool> _mutateItem(
    PdvCartLine line,
    Future<PdvCart> Function(
      PdvCartRepository repo,
      ({String userId, String idempotencyKey}) ctx,
    ) mutate,
  ) async {
    final ctx = _mutationContext();
    if (ctx == null) {
      return false;
    }

    state = state.copyWith(isMutating: true, busyLineId: line.id);

    try {
      final cart = await mutate(ref.read(pdvCartRepositoryProvider), ctx);
      _applyCart(cart);
      return true;
    } on ApiFailure {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    } catch (_) {
      state = state.copyWith(isMutating: false, clearBusyLineId: true);
      rethrow;
    }
  }

  void clear() {
    _clearPersistedCartKey();
    state = PdvCartState.initial;
    _didLoadForSession = false;
  }

  void setSelectedCliente({required String id, required String nome}) {
    state = state.copyWith(
      selectedClienteId: id,
      selectedClienteNome: nome,
    );
  }

  void clearSelectedCliente() {
    state = state.copyWith(clearSelectedCliente: true);
  }

  void applyCheckoutReset(String nextCartIdempotencyKey) {
    if (nextCartIdempotencyKey.isEmpty) {
      clear();
      return;
    }

    _persistIdempotencyKey(nextCartIdempotencyKey);
    state = PdvCartState(
      cart: PdvCart(idempotencyKey: nextCartIdempotencyKey),
      isLoading: false,
      isMutating: false,
    );
    _didLoadForSession = true;
  }
}

final pdvCartProvider =
    NotifierProvider<PdvCartController, PdvCartState>(PdvCartController.new);

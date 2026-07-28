import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado do refresh global no AppBar do shell.
@immutable
class PageRefreshState {
  const PageRefreshState({
    this.hasHandler = false,
    this.owner,
    this.isRefreshing = false,
  });

  final bool hasHandler;
  final Object? owner;
  final bool isRefreshing;

  bool get canRefresh => hasHandler && !isRefreshing;

  PageRefreshState copyWith({
    bool? hasHandler,
    Object? owner,
    bool? isRefreshing,
    bool clearHandler = false,
  }) {
    return PageRefreshState(
      hasHandler: clearHandler ? false : (hasHandler ?? this.hasHandler),
      owner: clearHandler ? null : (owner ?? this.owner),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class PageRefreshNotifier extends Notifier<PageRefreshState> {
  Future<void> Function()? _handler;

  @override
  PageRefreshState build() => const PageRefreshState();

  /// Actualiza o callback. Só notifica listeners quando a disponibilidade muda.
  void register({
    required Object owner,
    required Future<void> Function() handler,
  }) {
    _handler = handler;
    final already = state.hasHandler && state.owner == owner;
    if (already) return;

    state = PageRefreshState(
      hasHandler: true,
      owner: owner,
      isRefreshing: state.isRefreshing && state.owner == owner,
    );
  }

  void unregister(Object owner) {
    if (state.owner != owner) return;
    _handler = null;
    state = PageRefreshState(isRefreshing: state.isRefreshing);
  }

  Future<void> refresh() async {
    final handler = _handler;
    if (handler == null || state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true);
    try {
      await handler();
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }
}

final pageRefreshProvider =
    NotifierProvider<PageRefreshNotifier, PageRefreshState>(
  PageRefreshNotifier.new,
);

/// Regista o callback de refresh da página actual no AppBar global.
///
/// Usa [TickerMode] para cooperar com [TabBarView] (só a tab visível regista).
/// Nunca altera providers durante o build — o sync corre em post-frame.
class PageRefreshBinder extends ConsumerStatefulWidget {
  const PageRefreshBinder({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  ConsumerState<PageRefreshBinder> createState() => _PageRefreshBinderState();
}

class _PageRefreshBinderState extends ConsumerState<PageRefreshBinder> {
  final Object _owner = Object();
  PageRefreshNotifier? _notifier;
  bool _registered = false;
  bool _syncScheduled = false;
  late Future<void> Function() _latestOnRefresh = widget.onRefresh;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier ??= ref.read(pageRefreshProvider.notifier);
    _scheduleSync();
  }

  @override
  void didUpdateWidget(covariant PageRefreshBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _latestOnRefresh = widget.onRefresh;
    _scheduleSync();
  }

  @override
  void dispose() {
    final notifier = _notifier;
    final owner = _owner;
    final wasRegistered = _registered;
    _registered = false;
    // unregister fora do lifecycle síncrono (Riverpod não permite mutate em dispose)
    if (wasRegistered && notifier != null) {
      Future(() => notifier.unregister(owner));
    }
    super.dispose();
  }

  Future<void> _handleRefresh() => _latestOnRefresh();

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _syncRegistration();
    });
  }

  void _syncRegistration() {
    final notifier = _notifier;
    if (notifier == null) return;

    final active = TickerMode.valuesOf(context).enabled;
    if (active) {
      notifier.register(owner: _owner, handler: _handleRefresh);
      _registered = true;
    } else if (_registered) {
      notifier.unregister(_owner);
      _registered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TickerMode pode mudar entre frames (tabs); reagenda sem tocar no provider aqui.
    _scheduleSync();
    return widget.child;
  }
}

/// Invalida um provider e espera o próximo resultado (erros ficam no AsyncValue).
Future<void> invalidateAndWait(
  Future<void> Function() waitForReload,
) async {
  try {
    await waitForReload();
  } catch (_) {
    // Erros ficam no AsyncValue da página; o AppBar só precisa terminar o loading.
  }
}

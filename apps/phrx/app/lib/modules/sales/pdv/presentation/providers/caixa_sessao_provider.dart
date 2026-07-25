import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/caixa_sessao_repository_impl.dart';
import '../../domain/entities/caixa_disponivel.dart';
import '../../domain/entities/caixa_sessao.dart';

class CaixaSessaoState {
  const CaixaSessaoState({
    this.sessaoAtual,
    this.caixasDisponiveis = const <CaixaDisponivel>[],
    this.isLoading = false,
    this.isSubmitting = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final CaixaSessao? sessaoAtual;
  final List<CaixaDisponivel> caixasDisponiveis;
  final bool isLoading;
  final bool isSubmitting;
  final bool isInitialized;
  final String? errorMessage;

  bool get hasSessaoAberta => sessaoAtual != null;

  CaixaSessaoState copyWith({
    CaixaSessao? sessaoAtual,
    List<CaixaDisponivel>? caixasDisponiveis,
    bool? isLoading,
    bool? isSubmitting,
    bool? isInitialized,
    String? errorMessage,
    bool clearSessao = false,
    bool clearError = false,
  }) {
    return CaixaSessaoState(
      sessaoAtual: clearSessao ? null : (sessaoAtual ?? this.sessaoAtual),
      caixasDisponiveis: caixasDisponiveis ?? this.caixasDisponiveis,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CaixaSessaoController extends Notifier<CaixaSessaoState> {
  @override
  CaixaSessaoState build() {
    Future.microtask(refresh);
    return const CaixaSessaoState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(caixaSessaoRepositoryProvider);
      final sessaoAtual = await repository.getSessaoAtual();
      final caixasDisponiveis = sessaoAtual == null
          ? await repository.listCaixasDisponiveis()
          : const <CaixaDisponivel>[];

      state = state.copyWith(
        sessaoAtual: sessaoAtual,
        caixasDisponiveis: caixasDisponiveis,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadCaixasDisponiveis({bool force = false}) async {
    if (!force && state.caixasDisponiveis.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final caixasDisponiveis =
          await ref.read(caixaSessaoRepositoryProvider).listCaixasDisponiveis();
      state = state.copyWith(
        caixasDisponiveis: caixasDisponiveis,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> abrirCaixa({
    required String caixaId,
    required double valorAbertura,
  }) async {
    final userId = ref.read(authSessionProvider).session?.user.id;
    if (userId == null || userId.isEmpty) {
      throw const ApiFailure('Não foi possível identificar o utilizador autenticado.');
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref.read(caixaSessaoRepositoryProvider).abrirSessao(
            caixaId: caixaId,
            userId: userId,
            valorAbertura: valorAbertura,
          );
      await refresh();
      state = state.copyWith(isSubmitting: false, clearError: true);
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

  Future<void> fecharCaixa({
    required String sessaoId,
    required double valorContado,
    String? observacoes,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref.read(caixaSessaoRepositoryProvider).fecharSessao(
            sessaoId: sessaoId,
            valorContado: valorContado,
            observacoes: observacoes,
          );
      await refresh();
      state = state.copyWith(
        isSubmitting: false,
        clearSessao: true,
        clearError: true,
      );
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

final caixaSessaoProvider =
    NotifierProvider<CaixaSessaoController, CaixaSessaoState>(
  CaixaSessaoController.new,
);

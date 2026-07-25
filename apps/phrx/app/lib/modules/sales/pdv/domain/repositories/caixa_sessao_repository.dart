import '../entities/caixa_disponivel.dart';
import '../entities/caixa_sessao.dart';

abstract class CaixaSessaoRepository {
  Future<CaixaSessao?> getSessaoAtual();

  Future<List<CaixaDisponivel>> listCaixasDisponiveis();

  Future<void> abrirSessao({
    required String caixaId,
    required String userId,
    required double valorAbertura,
  });

  Future<void> fecharSessao({
    required String sessaoId,
    required double valorContado,
    String? observacoes,
  });
}

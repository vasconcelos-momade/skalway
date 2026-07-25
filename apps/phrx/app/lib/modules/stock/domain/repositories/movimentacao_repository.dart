import '../../domain/entities/movimentacao.dart';

abstract class MovimentacaoRepository {
  Future<MovimentacoesPageResult> listarMovimentacoes(MovimentacaoQuery query);
}

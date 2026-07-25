import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/movimentacao.dart';
import '../../domain/repositories/movimentacao_repository.dart';
import '../datasources/movimentacao_remote_datasource.dart';

class MovimentacaoRepositoryImpl implements MovimentacaoRepository {
  MovimentacaoRepositoryImpl(this._remoteDataSource);

  final MovimentacaoRemoteDataSource _remoteDataSource;

  @override
  Future<MovimentacoesPageResult> listarMovimentacoes(
    MovimentacaoQuery query,
  ) async {
    final response = await _remoteDataSource.listarMovimentacoes(query);
    return response.toEntity();
  }
}

final movimentacaoRepositoryProvider = Provider<MovimentacaoRepository>((ref) {
  return MovimentacaoRepositoryImpl(
    ref.watch(movimentacaoRemoteDataSourceProvider),
  );
});

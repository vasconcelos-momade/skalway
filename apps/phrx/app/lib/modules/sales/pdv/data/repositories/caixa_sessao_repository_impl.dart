import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/caixa_disponivel.dart';
import '../../domain/entities/caixa_sessao.dart';
import '../../domain/repositories/caixa_sessao_repository.dart';
import '../datasources/pdv_remote_datasource.dart';
import '../models/caixa_sessao_model.dart';

class CaixaSessaoRepositoryImpl implements CaixaSessaoRepository {
  CaixaSessaoRepositoryImpl(this._remoteDataSource);

  final PdvRemoteDataSource _remoteDataSource;

  @override
  Future<CaixaSessao?> getSessaoAtual() async {
    final response = await _remoteDataSource.getSessaoCaixaAtual();
    if (response == null) {
      return null;
    }
    return _toSessaoEntity(response);
  }

  @override
  Future<List<CaixaDisponivel>> listCaixasDisponiveis() async {
    final response = await _remoteDataSource.listCaixasDisponiveis();
    return response.map(_toCaixaDisponivelEntity).toList();
  }

  @override
  Future<void> abrirSessao({
    required String caixaId,
    required String userId,
    required double valorAbertura,
  }) async {
    await _remoteDataSource.abrirSessaoCaixa(
      AbrirSessaoCaixaRequestModel(
        caixaId: caixaId,
        userId: userId,
        valorAbertura: valorAbertura,
      ),
    );
  }

  @override
  Future<void> fecharSessao({
    required String sessaoId,
    required double valorContado,
    String? observacoes,
  }) async {
    await _remoteDataSource.fecharSessaoCaixa(
      FecharSessaoCaixaRequestModel(
        sessaoId: sessaoId,
        valorContado: valorContado,
        observacoes: observacoes,
      ),
    );
  }

  CaixaSessao _toSessaoEntity(CaixaSessaoModel model) {
    return CaixaSessao(
      id: model.id,
      caixaId: model.caixaId,
      terminalId: model.terminalId,
      userId: model.userId,
      abertura: model.abertura,
      sistema: model.sistema,
      contado: model.contado,
      diferenca: model.diferenca,
      observacaoFecho: model.observacaoFecho,
      fechadoPorId: model.fechadoPorId,
      status: model.status,
      openedAt: model.openedAt,
      closedAt: model.closedAt,
      deletedAt: model.deletedAt,
    );
  }

  CaixaDisponivel _toCaixaDisponivelEntity(CaixaDisponivelModel model) {
    return CaixaDisponivel(
      caixaId: model.caixaId,
      terminalId: model.terminalId,
      terminalCodigo: model.terminalCodigo,
      terminalNome: model.terminalNome,
      localizacao: model.localizacao,
    );
  }
}

final caixaSessaoRepositoryProvider = Provider<CaixaSessaoRepository>((ref) {
  return CaixaSessaoRepositoryImpl(ref.watch(pdvRemoteDataSourceProvider));
});

import '../../domain/entities/terminal.dart';

class TerminalDetalheModel {
  const TerminalDetalheModel({
    required this.id,
    required this.codigo,
    required this.nome,
    this.localizacao,
    this.ativo = true,
    this.caixaId,
  });

  final String id;
  final String codigo;
  final String nome;
  final String? localizacao;
  final bool ativo;
  final String? caixaId;

  factory TerminalDetalheModel.fromJson(Map<String, dynamic> json) {
    final caixa = json['caixa'];
    return TerminalDetalheModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      localizacao: _nullableString(json['localizacao']),
      ativo: json['ativo'] == true || json['ativo'] == 1,
      caixaId: caixa is Map<String, dynamic>
          ? caixa['id']?.toString()
          : json['caixaId']?.toString(),
    );
  }

  TerminalDetalhe toEntity() {
    return TerminalDetalhe(
      id: id,
      codigo: codigo,
      nome: nome,
      localizacao: localizacao,
      ativo: ativo,
      caixaId: caixaId,
    );
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

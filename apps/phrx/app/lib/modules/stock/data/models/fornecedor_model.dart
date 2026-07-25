import '../../domain/entities/fornecedor.dart';

class FornecedorResumoModel {
  const FornecedorResumoModel({
    required this.id,
    required this.nome,
    this.nuit,
    this.telefone,
    this.email,
  });

  final String id;
  final String nome;
  final String? nuit;
  final String? telefone;
  final String? email;

  factory FornecedorResumoModel.fromJson(Map<String, dynamic> json) {
    return FornecedorResumoModel(
      id: json['id']?.toString() ?? '',
      nome:
          json['nome']?.toString() ?? json['name']?.toString() ?? 'Fornecedor',
      nuit: _nullableString(json['nuit']),
      telefone: _nullableString(json['telefone']),
      email: _nullableString(json['email']),
    );
  }

  FornecedorResumo toEntity() {
    return FornecedorResumo(
      id: id,
      nome: nome,
      nuit: nuit,
      telefone: telefone,
      email: email,
    );
  }
}

class FornecedorDetalheModel {
  const FornecedorDetalheModel({
    required this.id,
    required this.nome,
    this.tipo,
    this.nuit,
    this.email,
    this.telefone,
    this.telefoneAlt,
    this.endereco,
    this.cidade,
    this.provincia,
    this.pais,
    this.contatoNome,
    this.observacoes,
    this.ativo = true,
  });

  final String id;
  final String nome;
  final String? tipo;
  final String? nuit;
  final String? email;
  final String? telefone;
  final String? telefoneAlt;
  final String? endereco;
  final String? cidade;
  final String? provincia;
  final String? pais;
  final String? contatoNome;
  final String? observacoes;
  final bool ativo;

  factory FornecedorDetalheModel.fromJson(Map<String, dynamic> json) {
    return FornecedorDetalheModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Fornecedor',
      tipo: _nullableString(json['tipo']),
      nuit: _nullableString(json['nuit']),
      email: _nullableString(json['email']),
      telefone: _nullableString(json['telefone']),
      telefoneAlt: _nullableString(json['telefoneAlt']),
      endereco: _nullableString(json['endereco']),
      cidade: _nullableString(json['cidade']),
      provincia: _nullableString(json['provincia']),
      pais: _nullableString(json['pais']),
      contatoNome: _nullableString(json['contatoNome']),
      observacoes: _nullableString(json['observacoes']),
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  FornecedorDetalhe toEntity() {
    return FornecedorDetalhe(
      id: id,
      nome: nome,
      tipo: tipo,
      nuit: nuit,
      email: email,
      telefone: telefone,
      telefoneAlt: telefoneAlt,
      endereco: endereco,
      cidade: cidade,
      provincia: provincia,
      pais: pais,
      contatoNome: contatoNome,
      observacoes: observacoes,
      ativo: ativo,
    );
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'nome': nome,
      if (tipo != null) 'tipo': tipo,
      if (nuit != null) 'nuit': nuit,
      if (email != null) 'email': email,
      if (telefone != null) 'telefone': telefone,
      if (telefoneAlt != null) 'telefoneAlt': telefoneAlt,
      if (endereco != null) 'endereco': endereco,
      if (cidade != null) 'cidade': cidade,
      if (provincia != null) 'provincia': provincia,
      if (pais != null) 'pais': pais,
      if (contatoNome != null) 'contatoNome': contatoNome,
      if (observacoes != null) 'observacoes': observacoes,
      'ativo': ativo,
    };
  }
}

String? _nullableString(dynamic value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

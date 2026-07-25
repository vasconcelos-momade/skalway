import '../../domain/entities/category.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
    this.productCount = 0,
  });

  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final int productCount;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] == true || json['ativo'] == 1,
      productCount: _toInt(json['productCount']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Category toEntity() => Category(
        id: id,
        nome: nome,
        descricao: descricao,
        ativo: ativo,
        productCount: productCount,
      );
}

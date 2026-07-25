import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/fornecedor_remote_datasource.dart';
import '../../domain/entities/fornecedor.dart';

final supplierListProvider = FutureProvider<List<FornecedorResumo>>((
  ref,
) async {
  final response = await ref.read(fornecedorRemoteDataSourceProvider).search(
        pageSize: 100,
      );
  return response.items
      .map(
        (item) => FornecedorResumo(
          id: item.id,
          nome: item.nome,
          nuit: item.nuit,
          telefone: item.telefone,
          email: item.email,
        ),
      )
      .toList();
});

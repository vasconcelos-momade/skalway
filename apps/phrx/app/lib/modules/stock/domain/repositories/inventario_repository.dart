import '../../../../../core/contracts/pagination_response.dart';
import '../entities/inventario.dart';

abstract class InventarioRepository {
  Future<InventarioDetalhe> abrirInventario(AbrirInventarioRequest request);
  Future<List<InventarioResumo>> listarInventarios({InventarioStatus? status});
  Future<PaginationResponse<InventarioProdutoApto>> listarProdutosAptos({
    String? query,
    String? categoriaId,
    String? estadoSanitario,
    int page = 1,
    int pageSize = 20,
  });
  Future<PaginationResponse<InventarioItem>> listarItensInventario({
    required String inventarioId,
    String? query,
    int page = 1,
    int pageSize = 20,
  });
  Future<InventarioDetalhe> obterInventario(String inventarioId);
  Future<InventarioDetalhe> iniciarContagem(String inventarioId);
  Future<InventarioItem> adicionarItem({
    required String inventarioId,
    required AdicionarInventarioItemRequest request,
  });
  Future<InventarioItem> registarContagem({
    required String inventarioId,
    required String itemId,
    required double estoqueContado,
  });
  Future<void> removerItem({
    required String inventarioId,
    required String itemId,
  });
  Future<InventarioDetalhe> reconciliar(String inventarioId);
  Future<InventarioDetalhe> cancelar(String inventarioId);
}

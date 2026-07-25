import '../../../../../core/contracts/pagination_response.dart';
import '../entities/inventario.dart';

abstract class InventarioRepository {
  Future<InventarioDetalhe> abrirInventario(AbrirInventarioRequest request);
  Future<List<InventarioResumo>> listarInventarios({InventarioStatus? status});
  Future<PaginationResponse<InventarioItem>> listarItensInventario({
    required String inventarioId,
    String? query,
    int page = 1,
    int pageSize = 20,
  });
  Future<InventarioDetalhe> obterInventario(String inventarioId);
  Future<InventarioDetalhe> iniciarContagem(String inventarioId);
  Future<InventarioItem> registarContagem({
    required String inventarioId,
    required String itemId,
    required double estoqueContado,
  });
  Future<InventarioDetalhe> reconciliar(String inventarioId);
  Future<InventarioDetalhe> cancelar(String inventarioId);
}

import '../../../../../core/contracts/pagination_response.dart';
import '../entities/estoque_dashboard.dart';
import '../entities/estoque_item.dart';

abstract class EstoqueRepository {
  Future<EstoqueDashboard> fetchDashboard();

  Future<PaginationResponse<EstoqueItem>> search({
    String? query,
    String? categoriaId,
    String? fornecedorId,
    String? estadoSanitario,
    String? disponibilidade,
    bool? semStock,
    bool? aExpirar,
    bool? expirado,
    String? validadeDe,
    String? validadeAte,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortOrder,
  });
}

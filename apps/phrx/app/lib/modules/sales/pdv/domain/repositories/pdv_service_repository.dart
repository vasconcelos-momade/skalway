import '../../../../../core/contracts/pagination_response.dart';
import '../entities/pdv_service.dart';

abstract class PdvServiceRepository {
  Future<PaginationResponse<PdvService>> searchServices({
    String? query,
    int page = 1,
    int pageSize = 10,
  });
}

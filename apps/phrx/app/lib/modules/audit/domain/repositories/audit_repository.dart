import '../../../../../core/contracts/pagination_response.dart';
import '../entities/audit_entities.dart';

abstract class AuditRepository {
  Future<AuditDashboard> getDashboard();

  Future<PaginationResponse<AuditLogEntry>> listLogs(AuditQuery query);

  Future<PaginationResponse<AuditEventSummary>> listEvents(AuditQuery query);
}

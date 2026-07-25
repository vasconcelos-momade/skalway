import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../domain/entities/audit_entities.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/audit_remote_datasource.dart';

class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl(this._remote);

  final AuditRemoteDataSource _remote;

  @override
  Future<AuditDashboard> getDashboard() => _remote.getDashboard();

  @override
  Future<PaginationResponse<AuditLogEntry>> listLogs(AuditQuery query) =>
      _remote.listLogs(query);

  @override
  Future<PaginationResponse<AuditEventSummary>> listEvents(AuditQuery query) =>
      _remote.listEvents(query);
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepositoryImpl(ref.watch(auditRemoteDataSourceProvider));
});

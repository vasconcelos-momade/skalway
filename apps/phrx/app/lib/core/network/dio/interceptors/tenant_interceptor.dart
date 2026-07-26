import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../constants/api_constants.dart';

/// Cabeçalhos multi-inquilino para rotas `/tenant/*` e `/central/sync/*`.
class TenantInterceptor extends Interceptor {
  TenantInterceptor(this._readContext);

  final ({String? tenantId, String? branchId}) Function() _readContext;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final needsTenant = path.startsWith('/tenant') || path.startsWith('/central/sync');
    if (needsTenant) {
      final ctx = _readContext();
      if (ctx.tenantId != null) {
        options.headers[ApiConstants.headerTenantId] = ctx.tenantId;
      }
      if (ctx.branchId != null) {
        options.headers[ApiConstants.headerBranchId] = ctx.branchId;
      }
    }
    handler.next(options);
  }
}

final tenantInterceptorProvider = Provider<TenantInterceptor>((ref) {
  return TenantInterceptor(() {
    final session = ref.read(authSessionProvider).session;
    return (tenantId: session?.tenantId, branchId: session?.branchId);
  });
});

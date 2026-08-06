import 'branch_access.dart';

class TenantAccess {
  const TenantAccess({
    required this.id,
    required this.tenantKey,
    required this.tenantName,
    required this.branches,
  });

  final String id;
  final String tenantKey;
  final String tenantName;
  final List<BranchAccess> branches;
}

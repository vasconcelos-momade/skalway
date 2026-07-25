import 'branch_access.dart';

class TenantAccess {
  const TenantAccess({
    required this.id,
    required this.companyName,
    required this.name,
    required this.branches,
  });

  final String id;
  final String companyName;
  final String name;
  final List<BranchAccess> branches;
}

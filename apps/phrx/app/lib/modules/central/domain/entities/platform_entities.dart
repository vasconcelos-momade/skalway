/// Entidades do painel administrativo SaaS (API central).
class PlatformTenantSummary {
  const PlatformTenantSummary({
    required this.id,
    required this.companyName,
    required this.tenantName,
    required this.status,
    required this.country,
    this.branchCount = 0,
    this.planName,
    this.monthlyValue,
    this.nextBillingAt,
    this.createdAt,
  });

  final String id;
  final String companyName;
  final String tenantName;
  final String status;
  final String country;
  final int branchCount;
  final String? planName;
  final double? monthlyValue;
  final DateTime? nextBillingAt;
  final DateTime? createdAt;
}

class PlatformTenantDetail {
  const PlatformTenantDetail({
    required this.summary,
    required this.branches,
    this.subscription,
    this.walletBalance,
  });

  final PlatformTenantSummary summary;
  final List<PlatformBranch> branches;
  final PlatformSubscription? subscription;
  final double? walletBalance;
}

class PlatformBranch {
  const PlatformBranch({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
    this.lastSyncAt,
    this.dbName,
    this.connectionStatus,
  });

  final String id;
  final String code;
  final String name;
  final bool active;
  final DateTime? lastSyncAt;
  final String? dbName;
  final String? connectionStatus;
}

class PlatformSubscription {
  const PlatformSubscription({
    required this.planName,
    required this.status,
    this.startDate,
    this.endDate,
    this.trialEndsAt,
    this.includedBranches = 0,
    this.usedBranches = 0,
    this.monthlyPrice,
  });

  final String planName;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? trialEndsAt;
  final int includedBranches;
  final int usedBranches;
  final double? monthlyPrice;
}

class PlatformInvoice {
  const PlatformInvoice({
    required this.id,
    required this.number,
    required this.tenantName,
    required this.planName,
    required this.period,
    required this.total,
    required this.paid,
    required this.balance,
    required this.status,
    this.dueDate,
  });

  final String id;
  final String number;
  final String tenantName;
  final String planName;
  final String period;
  final double total;
  final double paid;
  final double balance;
  final String status;
  final DateTime? dueDate;
}

class PlatformPayment {
  const PlatformPayment({
    required this.id,
    required this.tenantName,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
    required this.method,
    required this.reference,
    required this.status,
    this.confirmedAt,
  });

  final String id;
  final String tenantName;
  final String invoiceId;
  final String invoiceNumber;
  final double amount;
  final String method;
  final String reference;
  final String status;
  final DateTime? confirmedAt;
}

class RegisterTenantResult {
  const RegisterTenantResult({
    required this.id,
    required this.companyName,
    this.tenantName,
    this.branchCode,
  });

  final String id;
  final String companyName;
  final String? tenantName;
  final String? branchCode;
}

class RegisterTenantPayload {
  const RegisterTenantPayload({
    required this.nomeEmpresa,
    required this.nomeTenant,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPassword,
  });

  final String nomeEmpresa;
  final String nomeTenant;
  final String adminName;
  final String adminEmail;
  final String adminPassword;
  final String ownerName;
  final String ownerEmail;
  final String ownerPassword;

  Map<String, dynamic> toJson() => {
        'nomeEmpresa': nomeEmpresa,
        'nomeTenant': nomeTenant,
        'adminName': adminName,
        'adminEmail': adminEmail,
        'adminPassword': adminPassword,
        'ownerUser': {
          'name': ownerName,
          'email': ownerEmail,
          'password': ownerPassword,
          'role': 'admin',
        },
      };
}

class PlatformDashboardStats {
  const PlatformDashboardStats({
    this.totalClients = 0,
    this.activeClients = 0,
    this.trialClients = 0,
    this.suspendedClients = 0,
    this.monthlyRevenue = 0,
    this.openInvoices = 0,
    this.pendingPayments = 0,
    this.totalBranches = 0,
    this.recentTenants = const [],
    this.recentPayments = const [],
    this.alerts = const [],
  });

  final int totalClients;
  final int activeClients;
  final int trialClients;
  final int suspendedClients;
  final double monthlyRevenue;
  final int openInvoices;
  final int pendingPayments;
  final int totalBranches;
  final List<PlatformTenantSummary> recentTenants;
  final List<PlatformPayment> recentPayments;
  final List<String> alerts;
}

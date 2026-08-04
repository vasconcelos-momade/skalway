/// Entidades do painel administrativo SaaS (API central).
/// Valores financeiros vêm sempre do backend — sem cálculo local.
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
    this.isHeadOffice = false,
    this.lastSyncAt,
    this.dbName,
    this.connectionStatus,
  });

  final String id;
  final String code;
  final String name;
  final bool active;
  final bool isHeadOffice;
  final DateTime? lastSyncAt;
  final String? dbName;
  final String? connectionStatus;
}

/// Filial na listagem global (com contexto do tenant).
class PlatformBranchListItem {
  const PlatformBranchListItem({
    required this.tenantId,
    required this.tenantName,
    required this.companyName,
    required this.branch,
  });

  final String tenantId;
  final String tenantName;
  final String companyName;
  final PlatformBranch branch;
}

class PlatformEstimatedNextInvoice {
  const PlatformEstimatedNextInvoice({
    required this.amount,
    this.currency = 'MZN',
    this.periodStart,
    this.periodEnd,
    this.branchesUsed = 0,
    this.includedBranches = 0,
    this.extraBranches = 0,
    this.planMonthlyPrice = 0,
    this.extraBranchesCharge = 0,
    this.extraBranchPrice = 0,
  });

  final double amount;
  final String currency;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int branchesUsed;
  final int includedBranches;
  final int extraBranches;
  final double planMonthlyPrice;
  final double extraBranchesCharge;
  final double extraBranchPrice;
}

class PlatformSubscription {
  const PlatformSubscription({
    required this.planName,
    required this.status,
    this.planSlug,
    this.startDate,
    this.endDate,
    this.trialEndsAt,
    this.nextBillingAt,
    this.lastBillingAt,
    this.currentPeriodEnd,
    this.includedBranches = 0,
    this.usedBranches = 0,
    this.activeBranches = 0,
    this.extraBranches = 0,
    this.monthlyPrice,
    this.extraBranchPrice,
    this.estimatedMonthlyTotal,
    this.isEnterprise = false,
    this.trialDays,
    this.estimatedNextInvoice,
    this.lastInvoiceNumber,
    this.lastInvoiceStatus,
    this.lastInvoiceAmount,
    this.lastInvoiceDueDate,
    this.pendingTrialInvoiceId,
    this.pendingTrialInvoiceAmount,
    this.pendingTrialInvoiceDueDate,
  });

  final String planName;
  final String? planSlug;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? trialEndsAt;
  final DateTime? nextBillingAt;
  final DateTime? lastBillingAt;
  final DateTime? currentPeriodEnd;
  final int includedBranches;
  final int usedBranches;
  final int activeBranches;
  final int extraBranches;
  final double? monthlyPrice;
  final double? extraBranchPrice;
  final double? estimatedMonthlyTotal;
  final bool isEnterprise;
  final int? trialDays;
  final PlatformEstimatedNextInvoice? estimatedNextInvoice;
  final String? lastInvoiceNumber;
  final String? lastInvoiceStatus;
  final double? lastInvoiceAmount;
  final DateTime? lastInvoiceDueDate;
  final String? pendingTrialInvoiceId;
  final double? pendingTrialInvoiceAmount;
  final DateTime? pendingTrialInvoiceDueDate;

  bool get isTrial => status.toLowerCase() == 'trial';
}

class PlatformBranchHistoryItem {
  const PlatformBranchHistoryItem({
    required this.id,
    required this.action,
    required this.effectiveDate,
    this.branchId,
    this.branchCode,
    this.branchName,
    this.reason,
    this.createdByName,
    this.createdByEmail,
  });

  final String id;
  final String action;
  final DateTime effectiveDate;
  final String? branchId;
  final String? branchCode;
  final String? branchName;
  final String? reason;
  final String? createdByName;
  final String? createdByEmail;
}

class PlatformInvoice {
  const PlatformInvoice({
    required this.id,
    required this.tenantId,
    required this.number,
    required this.tenantName,
    required this.planName,
    required this.period,
    required this.total,
    required this.paid,
    required this.balance,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.branchesUsed,
    this.extraBranches,
    this.planMonthlyPrice,
    this.includedBranches,
    this.extraBranchPrice,
    this.subtotal,
  });

  final String id;
  final String tenantId;
  final String number;
  final String tenantName;
  final String planName;
  final String period;
  final double total;
  final double paid;
  final double balance;
  final String status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final int? branchesUsed;
  final int? extraBranches;
  final double? planMonthlyPrice;
  final int? includedBranches;
  final double? extraBranchPrice;
  final double? subtotal;
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
    this.email,
    this.endereco,
    this.nuit,
    this.telefone,
    this.planSlug = 'starter',
    this.status = 'trial',
    this.branchName,
    this.branchEndereco,
    this.branchContacto,
  });

  final String nomeEmpresa;
  final String nomeTenant;
  final String adminName;
  final String adminEmail;
  final String adminPassword;
  final String ownerName;
  final String ownerEmail;
  final String ownerPassword;
  final String? email;
  final String? endereco;
  final String? nuit;
  final String? telefone;
  final String planSlug;
  final String status;
  final String? branchName;
  final String? branchEndereco;
  final String? branchContacto;

  Map<String, dynamic> toJson() => {
        'nomeEmpresa': nomeEmpresa,
        'nomeTenant': nomeTenant,
        'slug': nomeTenant,
        'adminName': adminName,
        'adminEmail': adminEmail,
        'adminPassword': adminPassword,
        'email': email,
        'endereco': endereco,
        'nuit': nuit,
        'telefone': telefone,
        'planSlug': planSlug,
        'status': status,
        'branchName': branchName,
        'branchEndereco': branchEndereco,
        'branchContacto': branchContacto,
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

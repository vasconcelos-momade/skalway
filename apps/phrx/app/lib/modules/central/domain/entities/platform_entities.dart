/// Entidades do painel administrativo SaaS (API central).
/// Valores financeiros vêm sempre do backend — sem cálculo local.
class PlatformTenantSummary {
  const PlatformTenantSummary({
    required this.id,
    required this.tenantKey,
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
  final String tenantKey;
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
    required this.tenantKey,
    required this.tenantName,
    required this.branch,
  });

  final String tenantId;
  final String tenantKey;
  final String tenantName;
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
    this.walletBalance,
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
  final double? walletBalance;
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
    this.tenantKey,
    this.dueDate,
    this.paidAt,
    this.branchesUsed,
    this.extraBranches,
    this.planMonthlyPrice,
    this.includedBranches,
    this.extraBranchPrice,
    this.extrasAmount,
    this.subtotal,
    this.discount = 0,
    this.payableAmount,
  });

  final String id;
  final String tenantId;
  final String number;
  final String tenantName;
  final String? tenantKey;
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
  final double? extrasAmount;
  final double? subtotal;
  /// Desconto comercial absoluto (MZN) — valor da API.
  final double discount;
  /// Valor a pagar após desconto — valor da API.
  final double? payableAmount;

  bool get canConfirmPayment {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'parcial':
      case 'vencido':
      case 'vencida':
        return true;
      default:
        return false;
    }
  }

  bool get canApplyDiscount {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'parcial':
      case 'vencido':
      case 'vencida':
        return true;
      default:
        return false;
    }
  }
}

/// Métodos de pagamento suportados pela API Central.
abstract final class PlatformPaymentMethods {
  PlatformPaymentMethods._();

  static const cash = 'CASH';
  static const bankTransfer = 'BANK_TRANSFER';
  static const mpesa = 'MPESA';
  static const emola = 'EMOLA';

  static const all = <String>[cash, bankTransfer, mpesa, emola];

  static String label(String method) {
    switch (method.toUpperCase()) {
      case cash:
        return 'Cash';
      case bankTransfer:
        return 'Transferência Bancária';
      case mpesa:
        return 'M-Pesa';
      case emola:
        return 'E-Mola';
      default:
        return method;
    }
  }

  static bool requiresReference(String method) =>
      method.toUpperCase() != cash;
}

/// Meses de pagamento antecipado suportados pela API Wallet.
abstract final class PlatformPrepaidMonths {
  PlatformPrepaidMonths._();

  static const options = <int>[1, 3, 6, 12];
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
    required this.tenantName,
    this.tenantKey,
    this.branchCode,
  });

  final String id;
  final String tenantName;
  final String? tenantKey;
  final String? branchCode;
}

class RegisterTenantPayload {
  const RegisterTenantPayload({
    required this.tenantName,
    required this.ownerEmail,
    required this.ownerPassword,
    required this.branches,
    this.planSlug = 'starter',
    this.status = 'trial',
    this.billingPeriodMonths = 1,
  });

  final String tenantName;
  final String ownerEmail;
  final String ownerPassword;
  final List<String> branches;
  final String planSlug;
  final String status;
  final int billingPeriodMonths;

  Map<String, dynamic> toJson() => {
        'tenantName': tenantName,
        'email': ownerEmail,
        'planSlug': planSlug,
        'status': status,
        'billingPeriodMonths': billingPeriodMonths,
        'branches': branches.map((name) => {'name': name}).toList(),
        'ownerUser': {
          'name': tenantName,
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

class PlatformPlan {
  const PlatformPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.monthlyPrice,
    required this.includedBranches,
    required this.extraBranchPrice,
    required this.billingIntervalMonths,
    required this.trialDays,
    required this.active,
    required this.isEnterprise,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final double monthlyPrice;
  final int includedBranches;
  final double extraBranchPrice;
  final int billingIntervalMonths;
  final int trialDays;
  final bool active;
  final bool isEnterprise;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class PlatformPlanPayload {
  const PlatformPlanPayload({
    required this.name,
    required this.slug,
    required this.monthlyPrice,
    required this.includedBranches,
    required this.extraBranchPrice,
    required this.billingIntervalMonths,
    required this.trialDays,
    required this.active,
    required this.isEnterprise,
  });

  final String name;
  final String slug;
  final double monthlyPrice;
  final int includedBranches;
  final double extraBranchPrice;
  final int billingIntervalMonths;
  final int trialDays;
  final bool active;
  final bool isEnterprise;

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'monthlyPrice': monthlyPrice,
        'includedBranches': includedBranches,
        'extraBranchPrice': extraBranchPrice,
        'billingIntervalMonths': billingIntervalMonths,
        'trialDays': trialDays,
        'active': active,
        'isEnterprise': isEnterprise,
      };
}

class PlatformUser {
  const PlatformUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool active;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class PlatformUserPayload {
  const PlatformUserPayload({
    required this.name,
    required this.email,
    required this.role,
    this.password,
    this.active = true,
  });

  final String name;
  final String email;
  final String role;
  final String? password;
  final bool active;

  Map<String, dynamic> toJson({bool includePassword = true}) => {
        'name': name,
        'email': email,
        'role': role,
        'active': active,
        if (includePassword && password != null && password!.isNotEmpty)
          'password': password,
      };
}

class ConfirmInvoicePaymentPayload {
  const ConfirmInvoicePaymentPayload({
    required this.invoiceId,
    required this.amount,
    required this.method,
    this.reference,
    this.notes,
  });

  final String invoiceId;
  final double amount;
  final String method;
  final String? reference;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        'amount': amount,
        'method': method,
        if (reference != null && reference!.trim().isNotEmpty)
          'reference': reference!.trim(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class CreditWalletPayload {
  const CreditWalletPayload({
    required this.amount,
    required this.months,
    required this.method,
    this.reference,
    this.notes,
  });

  final double amount;
  final int months;
  final String method;
  final String? reference;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'months': months,
        'method': method,
        if (reference != null && reference!.trim().isNotEmpty)
          'reference': reference!.trim(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

/// Configuração institucional singleton da Central.
class PlatformCentralSettings {
  const PlatformCentralSettings({
    required this.id,
    required this.companyName,
    required this.companyNuit,
    required this.companyEmail,
    required this.companyPhone,
    required this.companyAddress,
    this.companyCity,
    this.companyProvince,
    this.companyCountry = 'MZ',
    this.companyLogo,
    this.mpesaAccountName,
    this.mpesaAccountNumber,
    this.emolaAccountName,
    this.emolaAccountNumber,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankAccountNib,
    this.bankAccountSwift,
    this.bankTransferInstructions,
    this.invoiceFooter,
    this.receiptFooter,
    this.defaultMessage,
    this.active = true,
  });

  final String id;
  final String companyName;
  final String companyNuit;
  final String companyEmail;
  final String companyPhone;
  final String companyAddress;
  final String? companyCity;
  final String? companyProvince;
  final String companyCountry;
  final String? companyLogo;
  final String? mpesaAccountName;
  final String? mpesaAccountNumber;
  final String? emolaAccountName;
  final String? emolaAccountNumber;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankAccountNib;
  final String? bankAccountSwift;
  final String? bankTransferInstructions;
  final String? invoiceFooter;
  final String? receiptFooter;
  final String? defaultMessage;
  final bool active;
}

class PlatformCentralSettingsPayload {
  const PlatformCentralSettingsPayload({
    required this.companyName,
    required this.companyNuit,
    required this.companyEmail,
    required this.companyPhone,
    required this.companyAddress,
    this.companyCity,
    this.companyProvince,
    this.companyCountry = 'MZ',
    this.companyLogo,
    this.mpesaAccountName,
    this.mpesaAccountNumber,
    this.emolaAccountName,
    this.emolaAccountNumber,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankAccountNib,
    this.bankAccountSwift,
    this.bankTransferInstructions,
    this.invoiceFooter,
    this.receiptFooter,
    this.defaultMessage,
    this.active = true,
  });

  final String companyName;
  final String companyNuit;
  final String companyEmail;
  final String companyPhone;
  final String companyAddress;
  final String? companyCity;
  final String? companyProvince;
  final String companyCountry;
  final String? companyLogo;
  final String? mpesaAccountName;
  final String? mpesaAccountNumber;
  final String? emolaAccountName;
  final String? emolaAccountNumber;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankAccountNib;
  final String? bankAccountSwift;
  final String? bankTransferInstructions;
  final String? invoiceFooter;
  final String? receiptFooter;
  final String? defaultMessage;
  final bool active;

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'companyNuit': companyNuit,
        'companyEmail': companyEmail,
        'companyPhone': companyPhone,
        'companyAddress': companyAddress,
        'companyCity': companyCity,
        'companyProvince': companyProvince,
        'companyCountry': companyCountry,
        'companyLogo': companyLogo,
        'mpesaAccountName': mpesaAccountName,
        'mpesaAccountNumber': mpesaAccountNumber,
        'emolaAccountName': emolaAccountName,
        'emolaAccountNumber': emolaAccountNumber,
        'bankName': bankName,
        'bankAccountName': bankAccountName,
        'bankAccountNumber': bankAccountNumber,
        'bankAccountNib': bankAccountNib,
        'bankAccountSwift': bankAccountSwift,
        'bankTransferInstructions': bankTransferInstructions,
        'invoiceFooter': invoiceFooter,
        'receiptFooter': receiptFooter,
        'defaultMessage': defaultMessage,
        'active': active,
      };
}

/// Entrada do AuditLog Central (API `/central/audit/logs`).
class PlatformAuditLogEntry {
  const PlatformAuditLogEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.createdAt,
    this.entityId,
    this.tenantId,
    this.tenantKey,
    this.tenantName,
    this.userName,
    this.ip,
    this.path,
  });

  final String id;
  final String action;
  final String entity;
  final DateTime createdAt;
  final String? entityId;
  final String? tenantId;
  final String? tenantKey;
  final String? tenantName;
  final String? userName;
  final String? ip;
  final String? path;

  factory PlatformAuditLogEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return PlatformAuditLogEntry(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      entityId: json['entityId']?.toString(),
      tenantId: json['tenantId']?.toString(),
      tenantKey: json['tenantKey']?.toString(),
      tenantName: json['tenantName']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      userName: user is Map<String, dynamic>
          ? (user['nome'] ?? user['name'])?.toString()
          : null,
      ip: json['ip']?.toString(),
      path: json['path']?.toString(),
    );
  }
}

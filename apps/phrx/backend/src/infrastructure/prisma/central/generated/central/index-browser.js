
Object.defineProperty(exports, "__esModule", { value: true });

const {
  Decimal,
  objectEnumValues,
  makeStrictEnum,
  Public,
  getRuntime,
  skip
} = require('./runtime/index-browser.js')


const Prisma = {}

exports.Prisma = Prisma
exports.$Enums = {}

/**
 * Prisma Client JS version: 5.22.0
 * Query Engine version: 605197351a3c8bdd595af2d2a9bc3025bca48ea2
 */
Prisma.prismaVersion = {
  client: "5.22.0",
  engine: "605197351a3c8bdd595af2d2a9bc3025bca48ea2"
}

Prisma.PrismaClientKnownRequestError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientKnownRequestError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)};
Prisma.PrismaClientUnknownRequestError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientUnknownRequestError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientRustPanicError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientRustPanicError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientInitializationError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientInitializationError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientValidationError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientValidationError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.NotFoundError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`NotFoundError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.Decimal = Decimal

/**
 * Re-export of sql-template-tag
 */
Prisma.sql = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`sqltag is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.empty = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`empty is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.join = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`join is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.raw = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`raw is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.validator = Public.validator

/**
* Extensions
*/
Prisma.getExtensionContext = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`Extensions.getExtensionContext is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.defineExtension = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`Extensions.defineExtension is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}

/**
 * Shorthand utilities for JSON filtering
 */
Prisma.DbNull = objectEnumValues.instances.DbNull
Prisma.JsonNull = objectEnumValues.instances.JsonNull
Prisma.AnyNull = objectEnumValues.instances.AnyNull

Prisma.NullTypes = {
  DbNull: objectEnumValues.classes.DbNull,
  JsonNull: objectEnumValues.classes.JsonNull,
  AnyNull: objectEnumValues.classes.AnyNull
}



/**
 * Enums
 */

exports.Prisma.TransactionIsolationLevel = makeStrictEnum({
  ReadUncommitted: 'ReadUncommitted',
  ReadCommitted: 'ReadCommitted',
  RepeatableRead: 'RepeatableRead',
  Serializable: 'Serializable'
});

exports.Prisma.UserScalarFieldEnum = {
  id: 'id',
  uuid: 'uuid',
  name: 'name',
  email: 'email',
  password: 'password',
  role: 'role',
  active: 'active',
  lastLoginAt: 'lastLoginAt',
  failedLoginCount: 'failedLoginCount',
  lockedUntil: 'lockedUntil',
  version: 'version',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.UserTenantScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  tenantId: 'tenantId',
  role: 'role',
  active: 'active',
  version: 'version',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.TenantScalarFieldEnum = {
  id: 'id',
  uuid: 'uuid',
  ownerUserId: 'ownerUserId',
  tenantKey: 'tenantKey',
  tenantName: 'tenantName',
  nuit: 'nuit',
  email: 'email',
  endereco: 'endereco',
  status: 'status',
  country: 'country',
  version: 'version',
  createdBy: 'createdBy',
  updatedBy: 'updatedBy',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.TenantSettingScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  key: 'key',
  value: 'value',
  schemaVersion: 'schemaVersion',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.BranchScalarFieldEnum = {
  id: 'id',
  uuid: 'uuid',
  tenantId: 'tenantId',
  code: 'code',
  name: 'name',
  isHeadOffice: 'isHeadOffice',
  active: 'active',
  syncEnabled: 'syncEnabled',
  offlineEnabled: 'offlineEnabled',
  connectionStatus: 'connectionStatus',
  lastSyncAt: 'lastSyncAt',
  syncVersion: 'syncVersion',
  dbHost: 'dbHost',
  dbPort: 'dbPort',
  dbName: 'dbName',
  dbUsername: 'dbUsername',
  dbPasswordCipherText: 'dbPasswordCipherText',
  dbPasswordIv: 'dbPasswordIv',
  dbPasswordTag: 'dbPasswordTag',
  dbSslEnabled: 'dbSslEnabled',
  version: 'version',
  createdBy: 'createdBy',
  updatedBy: 'updatedBy',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.DeviceScalarFieldEnum = {
  id: 'id',
  uuid: 'uuid',
  tenantId: 'tenantId',
  branchId: 'branchId',
  name: 'name',
  code: 'code',
  lastHeartbeatAt: 'lastHeartbeatAt',
  apiKeyHash: 'apiKeyHash',
  active: 'active',
  version: 'version',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.PrinterScalarFieldEnum = {
  id: 'id',
  uuid: 'uuid',
  tenantId: 'tenantId',
  branchId: 'branchId',
  deviceId: 'deviceId',
  name: 'name',
  type: 'type',
  connection: 'connection',
  ip: 'ip',
  port: 'port',
  model: 'model',
  manufacturer: 'manufacturer',
  active: 'active',
  version: 'version',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.PrintJobScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  branchId: 'branchId',
  printerId: 'printerId',
  document: 'document',
  payload: 'payload',
  status: 'status',
  attempts: 'attempts',
  maxAttempts: 'maxAttempts',
  errorMessage: 'errorMessage',
  printedAt: 'printedAt',
  lockedAt: 'lockedAt',
  lockedBy: 'lockedBy',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.SyncLogScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  branchId: 'branchId',
  deviceId: 'deviceId',
  entity: 'entity',
  entityId: 'entityId',
  operation: 'operation',
  payload: 'payload',
  payloadHash: 'payloadHash',
  schemaVersion: 'schemaVersion',
  status: 'status',
  retries: 'retries',
  nextRetryAt: 'nextRetryAt',
  error: 'error',
  checksum: 'checksum',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  syncedAt: 'syncedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.SyncSessionScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  branchId: 'branchId',
  deviceId: 'deviceId',
  status: 'status',
  startedAt: 'startedAt',
  endedAt: 'endedAt',
  bytesSent: 'bytesSent',
  bytesReceived: 'bytesReceived',
  recordsPushed: 'recordsPushed',
  recordsPulled: 'recordsPulled',
  conflictsCount: 'conflictsCount',
  errorMessage: 'errorMessage',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.PlanScalarFieldEnum = {
  id: 'id',
  name: 'name',
  slug: 'slug',
  monthlyPrice: 'monthlyPrice',
  includedBranches: 'includedBranches',
  extraBranchPrice: 'extraBranchPrice',
  isEnterprise: 'isEnterprise',
  active: 'active',
  billingIntervalMonths: 'billingIntervalMonths',
  trialDays: 'trialDays',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.SubscriptionScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  planId: 'planId',
  branchesUsed: 'branchesUsed',
  status: 'status',
  startDate: 'startDate',
  endDate: 'endDate',
  trialEndsAt: 'trialEndsAt',
  lastBillingAt: 'lastBillingAt',
  nextBillingAt: 'nextBillingAt',
  currentPeriodEnd: 'currentPeriodEnd',
  autoRenew: 'autoRenew',
  version: 'version',
  createdBy: 'createdBy',
  updatedBy: 'updatedBy',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.SubscriptionBranchHistoryScalarFieldEnum = {
  id: 'id',
  subscriptionId: 'subscriptionId',
  branchId: 'branchId',
  action: 'action',
  effectiveDate: 'effectiveDate',
  reason: 'reason',
  createdBy: 'createdBy',
  createdAt: 'createdAt'
};

exports.Prisma.InvoiceFiscalCounterScalarFieldEnum = {
  tenantId: 'tenantId',
  fiscalYear: 'fiscalYear',
  lastSequence: 'lastSequence',
  updatedAt: 'updatedAt'
};

exports.Prisma.InvoiceScalarFieldEnum = {
  id: 'id',
  uuid: 'uuid',
  number: 'number',
  tenantId: 'tenantId',
  fiscalYear: 'fiscalYear',
  sequence: 'sequence',
  subscriptionId: 'subscriptionId',
  billingSnapshotId: 'billingSnapshotId',
  amount: 'amount',
  discount: 'discount',
  paidAmount: 'paidAmount',
  remainingAmount: 'remainingAmount',
  status: 'status',
  dueDate: 'dueDate',
  paidAt: 'paidAt',
  periodStart: 'periodStart',
  periodEnd: 'periodEnd',
  branchesUsed: 'branchesUsed',
  extraBranches: 'extraBranches',
  description: 'description',
  version: 'version',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.BillingSnapshotScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  subscriptionId: 'subscriptionId',
  periodStart: 'periodStart',
  periodEnd: 'periodEnd',
  planMonthlyPrice: 'planMonthlyPrice',
  includedBranches: 'includedBranches',
  extraBranchesUsed: 'extraBranchesUsed',
  extraBranchPrice: 'extraBranchPrice',
  totalBranchesUsed: 'totalBranchesUsed',
  subtotal: 'subtotal',
  total: 'total',
  createdAt: 'createdAt'
};

exports.Prisma.TenantWalletScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  balance: 'balance',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.PaymentScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  invoiceId: 'invoiceId',
  amount: 'amount',
  method: 'method',
  status: 'status',
  reference: 'reference',
  proofUrl: 'proofUrl',
  coversFrom: 'coversFrom',
  coversTo: 'coversTo',
  monthsCovered: 'monthsCovered',
  confirmedAt: 'confirmedAt',
  confirmedBy: 'confirmedBy',
  createdBy: 'createdBy',
  updatedBy: 'updatedBy',
  notes: 'notes',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.PaymentWebhookScalarFieldEnum = {
  id: 'id',
  provider: 'provider',
  eventType: 'eventType',
  providerEventId: 'providerEventId',
  reference: 'reference',
  payload: 'payload',
  processed: 'processed',
  createdAt: 'createdAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.JobQueueScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  type: 'type',
  payload: 'payload',
  idempotencyKey: 'idempotencyKey',
  status: 'status',
  priority: 'priority',
  retries: 'retries',
  maxRetries: 'maxRetries',
  runAt: 'runAt',
  processedAt: 'processedAt',
  lockedAt: 'lockedAt',
  lockedBy: 'lockedBy',
  lastError: 'lastError',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.WalletTransactionScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  invoiceId: 'invoiceId',
  paymentId: 'paymentId',
  type: 'type',
  amount: 'amount',
  balanceAfter: 'balanceAfter',
  description: 'description',
  createdAt: 'createdAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.AuditLogScalarFieldEnum = {
  id: 'id',
  tenantId: 'tenantId',
  userId: 'userId',
  branchId: 'branchId',
  action: 'action',
  entity: 'entity',
  entityId: 'entityId',
  data: 'data',
  oldData: 'oldData',
  newData: 'newData',
  requestId: 'requestId',
  userAgent: 'userAgent',
  method: 'method',
  path: 'path',
  ip: 'ip',
  createdAt: 'createdAt'
};

exports.Prisma.UserSessionScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  deviceId: 'deviceId',
  tokenHash: 'tokenHash',
  refreshTokenHash: 'refreshTokenHash',
  expiresAt: 'expiresAt',
  revokedAt: 'revokedAt',
  revokedReason: 'revokedReason',
  lastActivityAt: 'lastActivityAt',
  ip: 'ip',
  userAgent: 'userAgent',
  createdAt: 'createdAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.LoginAttemptScalarFieldEnum = {
  id: 'id',
  email: 'email',
  ip: 'ip',
  userAgent: 'userAgent',
  success: 'success',
  userId: 'userId',
  createdAt: 'createdAt'
};

exports.Prisma.PermissionScalarFieldEnum = {
  id: 'id',
  code: 'code',
  name: 'name',
  deletedAt: 'deletedAt'
};

exports.Prisma.RolePermissionScalarFieldEnum = {
  id: 'id',
  permissionId: 'permissionId',
  role: 'role'
};

exports.Prisma.UserPermissionScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  permissionId: 'permissionId',
  tenantId: 'tenantId',
  allowed: 'allowed',
  deletedAt: 'deletedAt'
};

exports.Prisma.CentralSettingsScalarFieldEnum = {
  id: 'id',
  singletonKey: 'singletonKey',
  companyName: 'companyName',
  companyNuit: 'companyNuit',
  companyEmail: 'companyEmail',
  companyPhone: 'companyPhone',
  companyAddress: 'companyAddress',
  companyCity: 'companyCity',
  companyProvince: 'companyProvince',
  companyCountry: 'companyCountry',
  companyLogo: 'companyLogo',
  mpesaAccountName: 'mpesaAccountName',
  mpesaAccountNumber: 'mpesaAccountNumber',
  emolaAccountName: 'emolaAccountName',
  emolaAccountNumber: 'emolaAccountNumber',
  bankName: 'bankName',
  bankAccountName: 'bankAccountName',
  bankAccountNumber: 'bankAccountNumber',
  bankAccountNib: 'bankAccountNib',
  bankAccountSwift: 'bankAccountSwift',
  bankTransferInstructions: 'bankTransferInstructions',
  invoiceFooter: 'invoiceFooter',
  receiptFooter: 'receiptFooter',
  defaultMessage: 'defaultMessage',
  active: 'active',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  deletedAt: 'deletedAt'
};

exports.Prisma.SortOrder = {
  asc: 'asc',
  desc: 'desc'
};

exports.Prisma.JsonNullValueInput = {
  JsonNull: Prisma.JsonNull
};

exports.Prisma.NullableJsonNullValueInput = {
  DbNull: Prisma.DbNull,
  JsonNull: Prisma.JsonNull
};

exports.Prisma.NullsOrder = {
  first: 'first',
  last: 'last'
};

exports.Prisma.JsonNullValueFilter = {
  DbNull: Prisma.DbNull,
  JsonNull: Prisma.JsonNull,
  AnyNull: Prisma.AnyNull
};
exports.Role = exports.$Enums.Role = {
  superadmin: 'superadmin',
  admin: 'admin',
  usuario: 'usuario'
};

exports.TenantUserRole = exports.$Enums.TenantUserRole = {
  ADMIN: 'ADMIN',
  GERENTE: 'GERENTE',
  CAIXA: 'CAIXA',
  FARMACEUTICO: 'FARMACEUTICO',
  DIRETOR_TECNICO: 'DIRETOR_TECNICO'
};

exports.TenantStatus = exports.$Enums.TenantStatus = {
  trial: 'trial',
  ativo: 'ativo',
  pendente: 'pendente',
  grace: 'grace',
  suspenso: 'suspenso'
};

exports.BranchConnectionStatus = exports.$Enums.BranchConnectionStatus = {
  ONLINE: 'ONLINE',
  OFFLINE: 'OFFLINE',
  DEGRADED: 'DEGRADED'
};

exports.PrinterType = exports.$Enums.PrinterType = {
  ESC_POS: 'ESC_POS',
  A4: 'A4',
  LABEL: 'LABEL'
};

exports.PrinterConnection = exports.$Enums.PrinterConnection = {
  NETWORK: 'NETWORK',
  USB: 'USB',
  BLUETOOTH: 'BLUETOOTH',
  PDF: 'PDF'
};

exports.PrintStatus = exports.$Enums.PrintStatus = {
  PENDING: 'PENDING',
  PROCESSING: 'PROCESSING',
  PRINTED: 'PRINTED',
  FAILED: 'FAILED',
  CANCELLED: 'CANCELLED'
};

exports.SyncOperation = exports.$Enums.SyncOperation = {
  CREATE: 'CREATE',
  UPDATE: 'UPDATE',
  DELETE: 'DELETE'
};

exports.SyncStatus = exports.$Enums.SyncStatus = {
  PENDING: 'PENDING',
  PROCESSING: 'PROCESSING',
  SYNCED: 'SYNCED',
  FAILED: 'FAILED'
};

exports.SyncSessionStatus = exports.$Enums.SyncSessionStatus = {
  RUNNING: 'RUNNING',
  SUCCESS: 'SUCCESS',
  FAILED: 'FAILED',
  PARTIAL: 'PARTIAL'
};

exports.SubscriptionStatus = exports.$Enums.SubscriptionStatus = {
  trial: 'trial',
  ativo: 'ativo',
  cancelado: 'cancelado',
  expirado: 'expirado'
};

exports.SubscriptionBranchAction = exports.$Enums.SubscriptionBranchAction = {
  ADD: 'ADD',
  REMOVE: 'REMOVE'
};

exports.InvoiceStatus = exports.$Enums.InvoiceStatus = {
  pendente: 'pendente',
  parcial: 'parcial',
  pago: 'pago',
  vencido: 'vencido',
  cancelado: 'cancelado'
};

exports.PaymentMethod = exports.$Enums.PaymentMethod = {
  CASH: 'CASH',
  BANK_TRANSFER: 'BANK_TRANSFER',
  MPESA: 'MPESA',
  EMOLA: 'EMOLA',
  CARD: 'CARD',
  OTHER: 'OTHER'
};

exports.PaymentStatus = exports.$Enums.PaymentStatus = {
  pendente: 'pendente',
  confirmado: 'confirmado',
  falhado: 'falhado',
  cancelado: 'cancelado'
};

exports.JobStatus = exports.$Enums.JobStatus = {
  PENDING: 'PENDING',
  PROCESSING: 'PROCESSING',
  COMPLETED: 'COMPLETED',
  FAILED: 'FAILED',
  CANCELLED: 'CANCELLED'
};

exports.WalletTransactionType = exports.$Enums.WalletTransactionType = {
  CREDIT: 'CREDIT',
  DEBIT: 'DEBIT'
};

exports.Prisma.ModelName = {
  User: 'User',
  UserTenant: 'UserTenant',
  Tenant: 'Tenant',
  TenantSetting: 'TenantSetting',
  Branch: 'Branch',
  Device: 'Device',
  Printer: 'Printer',
  PrintJob: 'PrintJob',
  SyncLog: 'SyncLog',
  SyncSession: 'SyncSession',
  Plan: 'Plan',
  Subscription: 'Subscription',
  SubscriptionBranchHistory: 'SubscriptionBranchHistory',
  InvoiceFiscalCounter: 'InvoiceFiscalCounter',
  Invoice: 'Invoice',
  BillingSnapshot: 'BillingSnapshot',
  TenantWallet: 'TenantWallet',
  Payment: 'Payment',
  PaymentWebhook: 'PaymentWebhook',
  JobQueue: 'JobQueue',
  WalletTransaction: 'WalletTransaction',
  AuditLog: 'AuditLog',
  UserSession: 'UserSession',
  LoginAttempt: 'LoginAttempt',
  Permission: 'Permission',
  RolePermission: 'RolePermission',
  UserPermission: 'UserPermission',
  CentralSettings: 'CentralSettings'
};

/**
 * This is a stub Prisma Client that will error at runtime if called.
 */
class PrismaClient {
  constructor() {
    return new Proxy(this, {
      get(target, prop) {
        let message
        const runtime = getRuntime()
        if (runtime.isEdge) {
          message = `PrismaClient is not configured to run in ${runtime.prettyName}. In order to run Prisma Client on edge runtime, either:
- Use Prisma Accelerate: https://pris.ly/d/accelerate
- Use Driver Adapters: https://pris.ly/d/driver-adapters
`;
        } else {
          message = 'PrismaClient is unable to run in this browser environment, or has been bundled for the browser (running in `' + runtime.prettyName + '`).'
        }
        
        message += `
If this is unexpected, please open an issue: https://pris.ly/prisma-prisma-bug-report`

        throw new Error(message)
      }
    })
  }
}

exports.PrismaClient = PrismaClient

Object.assign(exports, Prisma)

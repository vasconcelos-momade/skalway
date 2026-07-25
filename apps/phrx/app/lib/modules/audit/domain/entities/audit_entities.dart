class AuditDashboard {
  const AuditDashboard({
    this.totalLogs = 0,
    this.logsLast24h = 0,
    this.criticalEventsLast7d = 0,
    this.permissionChangesLast7d = 0,
    this.userChangesLast7d = 0,
    this.recentEvents = const [],
  });

  final int totalLogs;
  final int logsLast24h;
  final int criticalEventsLast7d;
  final int permissionChangesLast7d;
  final int userChangesLast7d;
  final List<AuditEventSummary> recentEvents;

  factory AuditDashboard.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final raw = json['recentEvents'];
    return AuditDashboard(
      totalLogs: asInt(json['totalLogs']),
      logsLast24h: asInt(json['logsLast24h']),
      criticalEventsLast7d: asInt(json['criticalEventsLast7d']),
      permissionChangesLast7d: asInt(json['permissionChangesLast7d']),
      userChangesLast7d: asInt(json['userChangesLast7d']),
      recentEvents: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(AuditEventSummary.fromJson)
              .toList()
          : const [],
    );
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.createdAt,
    this.entityId,
    this.userName,
    this.ip,
  });

  final String id;
  final String action;
  final String entity;
  final DateTime createdAt;
  final String? entityId;
  final String? userName;
  final String? ip;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuditLogEntry(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      entityId: json['entityId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      userName: user is Map<String, dynamic>
          ? user['nome']?.toString()
          : null,
      ip: json['ip']?.toString(),
    );
  }
}

class AuditEventSummary {
  const AuditEventSummary({
    required this.id,
    required this.type,
    required this.entity,
    required this.createdAt,
    this.entityId,
    this.userName,
  });

  final String id;
  final String type;
  final String entity;
  final DateTime createdAt;
  final String? entityId;
  final String? userName;

  factory AuditEventSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuditEventSummary(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      entityId: json['entityId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      userName: user is Map<String, dynamic>
          ? user['nome']?.toString()
          : null,
    );
  }
}

class AuditQuery {
  const AuditQuery({
    this.page = 1,
    this.pageSize = 10,
    this.search = '',
    this.entity,
    this.action,
    this.type,
    this.dateFrom,
    this.dateTo,
  });

  final int page;
  final int pageSize;
  final String search;
  final String? entity;
  final String? action;
  final String? type;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  AuditQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? entity,
    String? action,
    String? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearEntity = false,
    bool clearAction = false,
    bool clearType = false,
    bool clearDateRange = false,
  }) {
    return AuditQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      entity: clearEntity ? null : (entity ?? this.entity),
      action: clearAction ? null : (action ?? this.action),
      type: clearType ? null : (type ?? this.type),
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
    );
  }

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      entity != null ||
      action != null ||
      type != null ||
      dateFrom != null ||
      dateTo != null;
}

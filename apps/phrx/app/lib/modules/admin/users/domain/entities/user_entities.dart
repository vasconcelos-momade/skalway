class TenantUserSummary {
  const TenantUserSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    required this.createdAt,
    this.email,
    this.permissionCount = 0,
  });

  final String id;
  final String name;
  final String role;
  final bool active;
  final DateTime createdAt;
  final String? email;
  final int permissionCount;
}

class UserDashboard {
  const UserDashboard({
    this.totalUtilizadores = 0,
    this.ativos = 0,
    this.inativos = 0,
    this.ultimosAcessos = const [],
  });

  final int totalUtilizadores;
  final int ativos;
  final int inativos;
  final List<UserLastAccess> ultimosAcessos;

  factory UserDashboard.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final rawAccess = json['ultimosAcessos'];
    return UserDashboard(
      totalUtilizadores: asInt(json['totalUtilizadores']),
      ativos: asInt(json['ativos']),
      inativos: asInt(json['inativos']),
      ultimosAcessos: rawAccess is List
          ? rawAccess
              .whereType<Map<String, dynamic>>()
              .map(UserLastAccess.fromJson)
              .toList()
          : const [],
    );
  }
}

class UserLastAccess {
  const UserLastAccess({
    required this.id,
    required this.action,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  final String id;
  final String action;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;

  factory UserLastAccess.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return UserLastAccess(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      userName: user is Map<String, dynamic> ? user['nome']?.toString() : null,
      userEmail:
          user is Map<String, dynamic> ? user['email']?.toString() : null,
    );
  }
}

class UserQuery {
  const UserQuery({
    this.page = 1,
    this.pageSize = 10,
    this.search = '',
    this.role,
    this.active,
  });

  final int page;
  final int pageSize;
  final String search;
  final String? role;
  final bool? active;

  UserQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? role,
    bool? active,
    bool clearRole = false,
    bool clearActive = false,
  }) {
    return UserQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      role: clearRole ? null : (role ?? this.role),
      active: clearActive ? null : (active ?? this.active),
    );
  }

  bool get hasFilters =>
      search.trim().isNotEmpty || role != null || active != null;
}

class TenantUserDetail {
  const TenantUserDetail({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.centralUserId,
    this.permissions = const [],
    this.stats = const UserDetailStats(),
  });

  final String id;
  final String name;
  final String role;
  final bool active;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final String? centralUserId;
  final List<UserPermissionOverride> permissions;
  final UserDetailStats stats;

  TenantUserSummary toSummary() => TenantUserSummary(
        id: id,
        name: name,
        role: role,
        active: active,
        createdAt: createdAt,
        email: email,
        permissionCount: permissions.length,
      );
}

class UserDetailStats {
  const UserDetailStats({
    this.faturas = 0,
    this.eventos = 0,
    this.auditLogs = 0,
  });

  final int faturas;
  final int eventos;
  final int auditLogs;
}

class UserPermissionOverride {
  const UserPermissionOverride({
    required this.module,
    required this.action,
    required this.allowed,
  });

  final String module;
  final String action;
  final bool allowed;
}

class UserEffectivePermission {
  const UserEffectivePermission({
    required this.module,
    required this.action,
    required this.allowed,
    required this.source,
  });

  final String module;
  final String action;
  final bool allowed;
  final String source;

  bool get isOverride => source == 'user_override';

  factory UserEffectivePermission.fromJson(Map<String, dynamic> json) {
    return UserEffectivePermission(
      module: json['module']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      allowed: json['allowed'] == true,
      source: json['source']?.toString() ?? 'role',
    );
  }
}

class UserEffectivePermissions {
  const UserEffectivePermissions({
    required this.userId,
    required this.role,
    this.permissions = const [],
  });

  final String userId;
  final String role;
  final List<UserEffectivePermission> permissions;

  factory UserEffectivePermissions.fromJson(Map<String, dynamic> json) {
    final raw = json['permissions'];
    return UserEffectivePermissions(
      userId: json['userId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      permissions: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(UserEffectivePermission.fromJson)
              .toList()
          : const [],
    );
  }
}

class UserFormPayload {
  const UserFormPayload({
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
    this.version,
  });

  final String name;
  final String email;
  final String role;
  final bool active;
  final int? version;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role,
        if (active != true) 'active': active,
        if (version != null) 'version': version,
      };
}

class UserAuditEntry {
  const UserAuditEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.createdAt,
    this.entityId,
  });

  final String id;
  final String action;
  final String entity;
  final String? entityId;
  final DateTime createdAt;
}

class UserEventEntry {
  const UserEventEntry({
    required this.id,
    required this.type,
    required this.entity,
    required this.createdAt,
    this.entityId,
  });

  final String id;
  final String type;
  final String entity;
  final String? entityId;
  final DateTime createdAt;
}

class RoleProfile {
  const RoleProfile({
    required this.role,
    required this.userCount,
    this.description,
  });

  final String role;
  final int userCount;
  final String? description;

  factory RoleProfile.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return RoleProfile(
      role: json['role']?.toString() ?? '',
      userCount: asInt(json['userCount']),
      description: json['description']?.toString(),
    );
  }
}

class RoleDetail {
  const RoleDetail({
    required this.role,
    this.description,
    this.userCount = 0,
    this.permissions = const [],
    this.users = const [],
  });

  final String role;
  final String? description;
  final int userCount;
  final List<RolePermission> permissions;
  final List<RoleUserRef> users;

  factory RoleDetail.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final rawPerms = json['permissions'];
    final rawUsers = json['users'];

    return RoleDetail(
      role: json['role']?.toString() ?? '',
      description: json['description']?.toString(),
      userCount: asInt(json['userCount']),
      permissions: rawPerms is List
          ? rawPerms
              .whereType<Map<String, dynamic>>()
              .map(RolePermission.fromJson)
              .toList()
          : const [],
      users: rawUsers is List
          ? rawUsers
              .whereType<Map<String, dynamic>>()
              .map(RoleUserRef.fromJson)
              .toList()
          : const [],
    );
  }
}

class RolePermission {
  const RolePermission({required this.module, required this.action});

  final String module;
  final String action;

  factory RolePermission.fromJson(Map<String, dynamic> json) {
    return RolePermission(
      module: json['module']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
    );
  }
}

class RoleUserRef {
  const RoleUserRef({
    required this.id,
    required this.name,
    required this.active,
    this.email,
  });

  final String id;
  final String name;
  final bool active;
  final String? email;

  factory RoleUserRef.fromJson(Map<String, dynamic> json) {
    return RoleUserRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      active: json['active'] == true,
      email: json['email']?.toString(),
    );
  }
}

class PermissionDashboard {
  const PermissionDashboard({
    this.totalRoleGrants = 0,
    this.totalUserOverrides = 0,
    this.grantsByRole = const [],
  });

  final int totalRoleGrants;
  final int totalUserOverrides;
  final List<RoleGrantCount> grantsByRole;

  factory PermissionDashboard.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final raw = json['grantsByRole'];
    return PermissionDashboard(
      totalRoleGrants: asInt(json['totalRoleGrants']),
      totalUserOverrides: asInt(json['totalUserOverrides']),
      grantsByRole: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(RoleGrantCount.fromJson)
              .toList()
          : const [],
    );
  }
}

class RoleGrantCount {
  const RoleGrantCount({required this.role, required this.count});

  final String role;
  final int count;

  factory RoleGrantCount.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return RoleGrantCount(
      role: json['role']?.toString() ?? '',
      count: asInt(json['count']),
    );
  }
}

class PermissionMatrixRow {
  const PermissionMatrixRow({
    required this.module,
    required this.actions,
  });

  final String module;
  final Map<String, dynamic> actions;

  factory PermissionMatrixRow.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    return PermissionMatrixRow(
      module: json['module']?.toString() ?? '',
      actions: rawActions is Map<String, dynamic> ? rawActions : const {},
    );
  }

  Map<String, bool> toBoolActions(List<String> standardActions) {
    return {
      for (final action in standardActions)
        action: actions[action] == true,
    };
  }
}

class RolePermissionGrant {
  const RolePermissionGrant({
    required this.module,
    required this.action,
    required this.enabled,
  });

  final String module;
  final String action;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'module': module,
        'action': action,
        'enabled': enabled,
      };
}

class UserPermissionGrant {
  const UserPermissionGrant({
    required this.module,
    required this.action,
    this.allowed,
    this.clear = false,
  });

  final String module;
  final String action;
  final bool? allowed;
  final bool clear;

  Map<String, dynamic> toJson() {
    if (clear) {
      return {
        'module': module,
        'action': action,
        'clear': true,
      };
    }
    return {
      'module': module,
      'action': action,
      'allowed': allowed ?? false,
    };
  }
}

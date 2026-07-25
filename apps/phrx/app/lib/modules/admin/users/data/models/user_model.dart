import '../../domain/entities/user_entities.dart';

class TenantUserModel {
  const TenantUserModel({
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

  factory TenantUserModel.fromJson(Map<String, dynamic> json) {
    return TenantUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      active: json['active'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      email: json['email']?.toString(),
      permissionCount: (json['permissionCount'] as num?)?.toInt() ?? 0,
    );
  }

  TenantUserSummary toEntity() {
    return TenantUserSummary(
      id: id,
      name: name,
      role: role,
      active: active,
      createdAt: createdAt,
      email: email,
      permissionCount: permissionCount,
    );
  }
}

class TenantUserDetailModel {
  const TenantUserDetailModel({
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
    this.stats = const UserDetailStatsModel(),
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
  final List<UserPermissionOverrideModel> permissions;
  final UserDetailStatsModel stats;

  factory TenantUserDetailModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final rawStats = json['stats'];

    return TenantUserDetailModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      active: json['active'] == true,
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      email: json['email']?.toString(),
      centralUserId: json['centralUserId']?.toString(),
      permissions: rawPerms is List
          ? rawPerms
              .whereType<Map<String, dynamic>>()
              .map(UserPermissionOverrideModel.fromJson)
              .toList()
          : const [],
      stats: rawStats is Map<String, dynamic>
          ? UserDetailStatsModel.fromJson(rawStats)
          : const UserDetailStatsModel(),
    );
  }

  TenantUserDetail toEntity() => TenantUserDetail(
        id: id,
        name: name,
        role: role,
        active: active,
        version: version,
        createdAt: createdAt,
        updatedAt: updatedAt,
        email: email,
        centralUserId: centralUserId,
        permissions: permissions.map((p) => p.toEntity()).toList(),
        stats: stats.toEntity(),
      );
}

class UserPermissionOverrideModel {
  const UserPermissionOverrideModel({
    required this.module,
    required this.action,
    required this.allowed,
  });

  final String module;
  final String action;
  final bool allowed;

  factory UserPermissionOverrideModel.fromJson(Map<String, dynamic> json) {
    return UserPermissionOverrideModel(
      module: json['module']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      allowed: json['allowed'] == true,
    );
  }

  UserPermissionOverride toEntity() => UserPermissionOverride(
        module: module,
        action: action,
        allowed: allowed,
      );
}

class UserDetailStatsModel {
  const UserDetailStatsModel({
    this.faturas = 0,
    this.eventos = 0,
    this.auditLogs = 0,
  });

  final int faturas;
  final int eventos;
  final int auditLogs;

  factory UserDetailStatsModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return UserDetailStatsModel(
      faturas: asInt(json['faturas']),
      eventos: asInt(json['eventos']),
      auditLogs: asInt(json['auditLogs']),
    );
  }

  UserDetailStats toEntity() => UserDetailStats(
        faturas: faturas,
        eventos: eventos,
        auditLogs: auditLogs,
      );
}

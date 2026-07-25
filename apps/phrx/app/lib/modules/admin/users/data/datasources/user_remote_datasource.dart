import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../../../../core/utils/api_list_response.dart';
import '../../domain/entities/user_entities.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<PaginationResponse<TenantUserModel>> listUsers(UserQuery query);

  Future<UserDashboard> getUserDashboard();

  Future<TenantUserDetailModel> getUser(String id);

  Future<TenantUserDetailModel> createUser(Map<String, dynamic> payload);

  Future<TenantUserDetailModel> updateUser(String id, Map<String, dynamic> payload);

  Future<void> deleteUser(String id);

  Future<PaginationResponse<Map<String, dynamic>>> listUserAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<Map<String, dynamic>>> listUserEvents(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<UserEffectivePermissions> getUserEffectivePermissions(String id);

  Future<UserEffectivePermissions> getCurrentUserEffectivePermissions();

  Future<List<RoleProfile>> listRoles();

  Future<RoleDetail> getRoleDetail(String role);

  Future<List<PermissionMatrixRow>> getPermissionMatrix({String? role});

  Future<PermissionDashboard> getPermissionDashboard();

  Future<void> updateRolePermissions(
    String role,
    List<RolePermissionGrant> grants,
  );

  Future<void> updateUserPermissions(
    String userId,
    List<UserPermissionGrant> permissions,
  );
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<TenantUserModel>> listUsers(UserQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantUtilizadores,
        queryParameters: <String, dynamic>{
          'page': query.page,
          'pageSize': query.pageSize,
          if (query.search.trim().isNotEmpty) 'q': query.search.trim(),
          if (query.role != null) 'role': query.role,
          if (query.active != null) 'active': query.active,
        },
      );

      return parseApiListResponse(
        data: response.data,
        itemMapper: TenantUserModel.fromJson,
        fallbackPage: query.page,
        fallbackPageSize: query.pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<UserDashboard> getUserDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantUtilizadoresDashboard,
      );
      final data = response.data;
      if (data == null) return const UserDashboard();
      return UserDashboard.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TenantUserDetailModel> getUser(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantUtilizador(id),
      );
      final data = response.data;
      if (data == null) throw const ApiFailure('Utilizador não encontrado.');
      return TenantUserDetailModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TenantUserDetailModel> createUser(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantUtilizadores,
        data: payload,
      );
      final data = response.data;
      if (data == null) throw const ApiFailure('Resposta inválida.');
      return TenantUserDetailModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<TenantUserDetailModel> updateUser(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.tenantUtilizador(id),
        data: payload,
      );
      final data = response.data;
      if (data == null) throw const ApiFailure('Resposta inválida.');
      return TenantUserDetailModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete<void>(ApiConstants.tenantUtilizador(id));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<PaginationResponse<Map<String, dynamic>>> _listSubResource(
    String path, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return parseApiListResponse(
        data: response.data,
        itemMapper: (json) => json,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PaginationResponse<Map<String, dynamic>>> listUserAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) =>
      _listSubResource(
        ApiConstants.tenantUtilizadorAuditoria(id),
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<PaginationResponse<Map<String, dynamic>>> listUserEvents(
    String id, {
    int page = 1,
    int pageSize = 10,
  }) =>
      _listSubResource(
        ApiConstants.tenantUtilizadorEventos(id),
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<UserEffectivePermissions> getUserEffectivePermissions(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantUtilizadorPermissoes(id),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Permissões não encontradas.');
      }
      return UserEffectivePermissions.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<UserEffectivePermissions> getCurrentUserEffectivePermissions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantUtilizadorAtualPermissoes,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Permissões da sessão não encontradas.');
      }
      return UserEffectivePermissions.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<RoleProfile>> listRoles() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPerfis,
      );
      return ApiEnvelope.unwrapList(response.data)
          .map(RoleProfile.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<RoleDetail> getRoleDetail(String role) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPerfil(role),
      );
      final data = response.data;
      if (data == null) throw const ApiFailure('Perfil não encontrado.');
      return RoleDetail.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<List<PermissionMatrixRow>> getPermissionMatrix({String? role}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPermissoes,
        queryParameters: role == null ? null : <String, dynamic>{'role': role},
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      final modules = payload['modules'];
      if (modules is! List) return const [];
      return modules
          .whereType<Map<String, dynamic>>()
          .map(PermissionMatrixRow.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<PermissionDashboard> getPermissionDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPermissoesDashboard,
      );
      final data = response.data;
      if (data == null) return const PermissionDashboard();
      return PermissionDashboard.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> updateRolePermissions(
    String role,
    List<RolePermissionGrant> grants,
  ) async {
    try {
      await _dio.put<void>(
        ApiConstants.tenantPerfilPermissoes(role),
        data: {
          'grants': grants.map((g) => g.toJson()).toList(),
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> updateUserPermissions(
    String userId,
    List<UserPermissionGrant> permissions,
  ) async {
    try {
      await _dio.put<void>(
        ApiConstants.tenantUtilizadorPermissoes(userId),
        data: {
          'permissions': permissions.map((p) => p.toJson()).toList(),
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(ref.watch(dioProvider));
});

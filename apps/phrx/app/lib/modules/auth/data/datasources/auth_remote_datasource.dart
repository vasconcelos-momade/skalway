import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../models/login_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralAuthLogin,
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida do servidor.');
      }
      if (data['success'] == false) {
        final err = data['error'];
        final msg = err is Map ? err['message'] : err;
        throw ApiFailure(
          msg is String && msg.isNotEmpty ? msg : 'Falha na autenticação.',
          statusCode: response.statusCode,
        );
      }
      return LoginResponseModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.centralAuthForgotPassword,
        data: <String, dynamic>{'email': email.trim()},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Resposta inválida do servidor.');
      }
      if (data['success'] == false) {
        final err = data['error'];
        final msg = err is Map ? err['message'] : err;
        throw ApiFailure(
          msg is String && msg.isNotEmpty ? msg : 'Falha ao solicitar recuperação.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioProvider));
});

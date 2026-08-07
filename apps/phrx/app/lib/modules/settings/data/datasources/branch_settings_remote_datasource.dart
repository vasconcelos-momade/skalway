import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/contracts/api_envelope.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/dio/dio_provider.dart';
import '../models/branch_settings_model.dart';

abstract class BranchSettingsRemoteDataSource {
  Future<BranchSettingsSnapshot> getActive();
  Future<BranchSettingsSnapshot> update(Map<String, dynamic> settings);
}

class BranchSettingsRemoteDataSourceImpl
    implements BranchSettingsRemoteDataSource {
  BranchSettingsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<BranchSettingsSnapshot> getActive() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.branchSettings,
      );
      return BranchSettingsSnapshot.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<BranchSettingsSnapshot> update(Map<String, dynamic> settings) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.branchSettings,
        data: <String, dynamic>{'settings': settings},
      );
      return BranchSettingsSnapshot.fromJson(
        ApiEnvelope.unwrapMap(response.data ?? {}),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

final branchSettingsRemoteDataSourceProvider =
    Provider<BranchSettingsRemoteDataSource>(
  (ref) => BranchSettingsRemoteDataSourceImpl(ref.watch(dioProvider)),
);

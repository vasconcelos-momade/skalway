import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/network/dio/dio_provider.dart';

typedef ReportFilePayload =
    ({Uint8List bytes, String fileName, String contentType});

abstract class ReportApi {
  Future<ReportFilePayload> fetchReport({
    required String path,
    required String format,
    required String disposition,
    Map<String, dynamic>? queryParameters,
  });
}

class DioReportApi implements ReportApi {
  DioReportApi(this._dio);

  final Dio _dio;

  @override
  Future<ReportFilePayload> fetchReport({
    required String path,
    required String format,
    required String disposition,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: <String, dynamic>{
          ...?queryParameters,
          'format': format,
          'disposition': disposition,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final rawBytes = response.data;
      if (rawBytes == null || rawBytes.isEmpty) {
        throw const ApiFailure('Falha ao carregar o relatório.');
      }

      final headers = response.headers;
      final dispositionHeader = headers.value('content-disposition');
      final contentType =
          headers.value(Headers.contentTypeHeader) ?? 'application/octet-stream';

      return (
        bytes: Uint8List.fromList(rawBytes),
        fileName: _extractFileName(
          dispositionHeader,
          fallback: 'relatorio.$format',
        ),
        contentType: contentType,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  String _extractFileName(String? disposition, {required String fallback}) {
    if (disposition == null || disposition.trim().isEmpty) {
      return fallback;
    }

    final utf8Match = RegExp(
      r'''filename\*=UTF-8''([^;]+)''',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!).trim();
    }

    final quotedMatch = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (quotedMatch != null) {
      return quotedMatch.group(1)!.trim();
    }

    final plainMatch = RegExp(
      r'filename=([^;]+)',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (plainMatch != null) {
      return plainMatch.group(1)!.trim();
    }

    return fallback;
  }
}

final reportApiProvider = Provider<ReportApi>((ref) {
  return DioReportApi(ref.watch(dioProvider));
});

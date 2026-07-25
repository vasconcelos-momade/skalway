import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'report_api.dart';

class ReportRepository {
  ReportRepository(this._api);

  final ReportApi _api;

  Future<ReportFilePayload> fetchReport({
    required String path,
    required String format,
    required String disposition,
    Map<String, dynamic>? queryParameters,
  }) {
    return _api.fetchReport(
      path: path,
      format: format,
      disposition: disposition,
      queryParameters: queryParameters,
    );
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(reportApiProvider));
});

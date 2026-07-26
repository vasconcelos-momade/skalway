import '../contracts/api_envelope.dart';
import '../contracts/pagination_response.dart';

int apiAsInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

PaginationResponse<T> parseApiListResponse<T>({
  required Map<String, dynamic>? data,
  required T Function(Map<String, dynamic>) itemMapper,
  int fallbackPage = 1,
  int fallbackPageSize = 20,
}) {
  if (data == null) {
    return PaginationResponse<T>(items: const [], page: fallbackPage, pageSize: fallbackPageSize);
  }

  final rawItems = data['data'];
  final meta = ApiEnvelope.unwrapMeta(data) ?? <String, dynamic>{};
  final items = rawItems is List
      ? rawItems.whereType<Map<String, dynamic>>().map(itemMapper).toList()
      : <T>[];

  final rawSummary = meta['summary'];
  return PaginationResponse<T>(
    items: items,
    page: apiAsInt(meta['page'], fallback: fallbackPage),
    pageSize: apiAsInt(meta['pageSize'], fallback: fallbackPageSize),
    hasMore: meta['hasMore'] == true,
    totalCount: meta['totalCount'] == null
        ? null
        : apiAsInt(meta['totalCount'], fallback: 0),
    summary: rawSummary is Map<String, dynamic>
        ? PaginationSummary.fromJson(rawSummary)
        : null,
  );
}

import '../utils/dashboard_data_utils.dart';

class DashboardPagedTableResult {
  const DashboardPagedTableResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalCount,
    this.totalPages,
    this.hasPrevious = false,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final int? totalPages;
  final bool hasPrevious;

  factory DashboardPagedTableResult.fromMap(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final page = asInt(json['page'], fallback: 1);
    final pageSize = asInt(json['pageSize'], fallback: 10);
    final totalCount =
        json['totalCount'] == null ? null : asInt(json['totalCount']);
    final totalPages = json['totalPages'] == null
        ? (totalCount == null
            ? null
            : (totalCount / pageSize).ceil().clamp(1, 9999))
        : asInt(json['totalPages'], fallback: 1);

    return DashboardPagedTableResult(
      items: DashboardDataUtils.list(json['items']),
      page: page,
      pageSize: pageSize,
      hasMore: json['hasMore'] == true,
      totalCount: totalCount,
      totalPages: totalPages,
      hasPrevious: json['hasPrevious'] == true || page > 1,
    );
  }
}

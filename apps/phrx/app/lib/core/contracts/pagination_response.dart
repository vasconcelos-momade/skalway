abstract final class PaginationDefaults {
  static const pageSize = 10;
}

/// Gera os itens da barra de paginação no padrão `< 1 2 3 4 5 6 ... 58 >`.
List<Object> buildEnterprisePageItems({
  required int page,
  required int totalPages,
}) {
  if (totalPages <= 0) return const [];
  if (totalPages <= 7) {
    return List<Object>.generate(totalPages, (index) => index + 1);
  }

  final items = <Object>[];
  late final List<int> visiblePages;

  if (page <= 4) {
    visiblePages = [1, 2, 3, 4, 5, 6, totalPages];
  } else if (page >= totalPages - 3) {
    visiblePages = [
      1,
      totalPages - 5,
      totalPages - 4,
      totalPages - 3,
      totalPages - 2,
      totalPages - 1,
      totalPages,
    ];
  } else {
    visiblePages = [1, page - 2, page - 1, page, page + 1, page + 2, totalPages];
  }

  final sortedPages = visiblePages
      .where((p) => p >= 1 && p <= totalPages)
      .toSet()
      .toList()
    ..sort();

  int? lastPage;
  for (final p in sortedPages) {
    if (lastPage != null && p - lastPage > 1) {
      items.add('...');
    }
    items.add(p);
    lastPage = p;
  }
  return items;
}

class PaginationSummary {
  const PaginationSummary({
    this.total = 0,
    this.paid = 0,
    this.pending = 0,
    this.cancelled = 0,
  });

  final int total;
  final int paid;
  final int pending;
  final int cancelled;

  factory PaginationSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return PaginationSummary(
      total: asInt(json['total']),
      paid: asInt(json['paid']),
      pending: asInt(json['pending']),
      cancelled: asInt(json['cancelled']),
    );
  }
}

class PaginationResponse<T> {
  const PaginationResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.nextCursor,
    this.hasMore = false,
    this.totalCount,
    this.summary,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final String? nextCursor;
  final bool hasMore;
  final int? totalCount;
  final PaginationSummary? summary;
}

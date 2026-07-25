import '../domain/entities/invoice_summary.dart';

/// Cache em memória da lista de faturas (mesmo padrão do catálogo PDV).
abstract final class InvoiceCachePolicy {
  InvoiceCachePolicy._();

  static const Duration entryTtl = Duration(seconds: 45);

  static final Map<String, _InvoiceCacheEntry<dynamic>> _entries =
      <String, _InvoiceCacheEntry<dynamic>>{};

  static T? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) {
      return null;
    }
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  static void put<T>(String key, T value) {
    _entries[key] = _InvoiceCacheEntry<dynamic>(
      value: value,
      expiresAt: DateTime.now().add(entryTtl),
    );
  }

  static void clear() {
    _entries.clear();
  }

  static String queryKey(InvoiceQuery query) {
    return [
      query.page,
      query.pageSize,
      query.search.trim().toLowerCase(),
      query.clienteId ?? '',
      query.status ?? '',
      query.dateFrom?.toIso8601String() ?? '',
      query.dateTo?.toIso8601String() ?? '',
      query.terminalId ?? '',
      query.userId ?? '',
      query.quickFilter.name,
    ].join('|');
  }
}

class _InvoiceCacheEntry<T> {
  _InvoiceCacheEntry({
    required this.value,
    required this.expiresAt,
  });

  final T value;
  final DateTime expiresAt;
}

/// Limpa cache de faturas (ex.: após venda no PDV ou cancelamento).
void invalidateInvoiceListCache() {
  InvoiceCachePolicy.clear();
}

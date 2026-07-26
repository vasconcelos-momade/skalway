abstract final class InventoryCatalogCachePolicy {
  InventoryCatalogCachePolicy._();

  static const Duration entryTtl = Duration(seconds: 45);

  static final Map<String, _InventoryCacheEntry<dynamic>> _entries =
      <String, _InventoryCacheEntry<dynamic>>{};

  static void clear() {
    _entries.clear();
  }

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
    _entries[key] = _InventoryCacheEntry<dynamic>(
      value: value,
      expiresAt: DateTime.now().add(entryTtl),
    );
  }

  static String itemPageKey({
    required String inventoryId,
    required String query,
    required int page,
    required int pageSize,
  }) {
    return [
      inventoryId,
      query.toLowerCase(),
      page,
      pageSize,
    ].join('|');
  }
}

class _InventoryCacheEntry<T> {
  _InventoryCacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;
}

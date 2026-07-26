/// Cache em memória do catálogo PDV (produtos), com TTL e `catalogVersion`.
abstract final class PdvCatalogCachePolicy {
  PdvCatalogCachePolicy._();

  static const Duration entryTtl = Duration(seconds: 45);

  static String? activeCatalogVersion;

  static final Map<String, _PdvCacheEntry<dynamic>> _entries =
      <String, _PdvCacheEntry<dynamic>>{};

  static void setCatalogVersion(String? version) {
    final normalized = version?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    if (activeCatalogVersion != normalized) {
      activeCatalogVersion = normalized;
      _entries.clear();
    }
  }

  static void clear() {
    activeCatalogVersion = null;
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
    _entries[key] = _PdvCacheEntry<dynamic>(
      value: value,
      expiresAt: DateTime.now().add(entryTtl),
    );
  }

  static String productPageKey({
    required String query,
    required String? categoria,
    required int page,
    required int pageSize,
  }) {
    final version = activeCatalogVersion ?? 'none';
    final normalizedCategoria = categoria?.trim().toUpperCase() ?? 'all';
    return '$version|$normalizedCategoria|${query.toLowerCase()}|$page|$pageSize';
  }
}

class _PdvCacheEntry<T> {
  _PdvCacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;
}

/// Limpa cache de produtos no PDV (ex.: após venda ou mudança de branch).
void invalidatePdvProductCatalogCache() {
  PdvCatalogCachePolicy.clear();
}

/// Leitura de stock por lote a partir dos contratos actuais da API
/// (`LoteStockBalance`: `quantidadeTotal`, `quantidadeDisponivel`).
class LoteStockUtils {
  LoteStockUtils._();

  static double readDisponivel(Map<String, dynamic>? data) {
    if (data == null) {
      return 0;
    }

    final topLevel = _toDouble(data['quantidadeDisponivel']);
    if (topLevel > 0) {
      return topLevel;
    }

    final balance = data['stockBalance'];
    if (balance is Map) {
      final nested = _toDouble(balance['quantidadeDisponivel']);
      if (nested > 0) {
        return nested;
      }
      final total = _toDouble(balance['quantidadeTotal']);
      if (total > 0) {
        return _disponivelFromTotal(total, data['quantidadeQuarentena']);
      }
    }

    final total = _toDouble(data['quantidadeTotal']);
    if (total > 0) {
      return _disponivelFromTotal(total, data['quantidadeQuarentena']);
    }

    return topLevel;
  }

  static double readTotal(Map<String, dynamic>? data) {
    if (data == null) {
      return 0;
    }

    final topLevel = _toDouble(data['quantidadeTotal']);
    if (topLevel > 0) {
      return topLevel;
    }

    final balance = data['stockBalance'];
    if (balance is Map) {
      final nested = _toDouble(balance['quantidadeTotal']);
      if (nested > 0) {
        return nested;
      }
      final disponivel = _toDouble(balance['quantidadeDisponivel']);
      if (disponivel > 0) {
        return disponivel;
      }
    }

    final disponivel = _toDouble(data['quantidadeDisponivel']);
    if (disponivel > 0) {
      return disponivel;
    }

    return topLevel;
  }

  static String formatDisponivel(Map<String, dynamic>? data) {
    return _formatQuantity(readDisponivel(data));
  }

  static String formatTotal(Map<String, dynamic>? data) {
    return _formatQuantity(readTotal(data));
  }

  static String formatDisponivelFromNum(num value) {
    return _formatQuantity(value.toDouble());
  }

  static double _disponivelFromTotal(double total, dynamic quarentena) {
    final blocked = _toDouble(quarentena);
    return total > blocked ? total - blocked : 0;
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}

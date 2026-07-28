/// Utilitários de parsing e formatação para dados do dashboard.
abstract final class DashboardDataUtils {
  DashboardDataUtils._();

  static String kpi(Map<String, dynamic>? data, String key, {String suffix = ''}) {
    final value = data?[key];
    if (value == null) return '—';
    if (value is num) {
      final rounded = value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
      return '$rounded$suffix';
    }
    return '$value$suffix';
  }

  static Map<String, dynamic>? map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> list(dynamic value) {
    if (value is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  /// Remove dias iniciais a zero para o gráfico mostrar a actividade recente.
  static List<Map<String, dynamic>> compactTimeSeries(
    List<Map<String, dynamic>> points, {
    List<String> valueKeys = const ['receitas', 'despesas', 'saldo', 'total'],
    int minPoints = 7,
    int leadingPadding = 1,
  }) {
    if (points.length <= minPoints) return points;

    var firstActive = -1;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final active = valueKeys.any((key) => _asDouble(point[key]) != 0);
      if (active) {
        firstActive = i;
        break;
      }
    }

    if (firstActive < 0) {
      return points.sublist(points.length - minPoints);
    }

    final earliestAllowed = points.length - minPoints;
    final start = firstActive - leadingPadding;
    final clampedStart =
        start < 0 ? 0 : (start > earliestAllowed ? earliestAllowed : start);
    return points.sublist(clampedStart);
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String label(dynamic value, {int max = 8}) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '—';
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return '${text.substring(8, 10)}/${text.substring(5, 7)}';
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(text)) {
      return '${text.substring(8, 10)}/${text.substring(5, 7)}';
    }
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(text)) {
      return '${text.substring(5, 7)}/${text.substring(2, 4)}';
    }
    if (text.length <= max) return text;
    return text.substring(0, max);
  }

  static String money(dynamic value) => '${value ?? 0} MZN';

  static String text(dynamic value, {String fallback = '—'}) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) return fallback;
    return normalized;
  }

  static String productName(Map<String, dynamic> row) {
    return text(
      row['produtoNomeComercial'] ??
          row['produtoNome'] ??
          row['nomeComercial'] ??
          row['nome'],
    );
  }
}

// Aliases retrocompatíveis — preferir DashboardDataUtils em código novo.
String dashKpi(Map<String, dynamic>? data, String key, {String suffix = ''}) =>
    DashboardDataUtils.kpi(data, key, suffix: suffix);

List<Map<String, dynamic>> dashList(dynamic value) => DashboardDataUtils.list(value);

Map<String, dynamic>? dashMap(dynamic value) => DashboardDataUtils.map(value);

String dashLabel(dynamic value, {int max = 8}) =>
    DashboardDataUtils.label(value, max: max);

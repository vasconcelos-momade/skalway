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

  static List<Map<String, dynamic>> list(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  static Map<String, dynamic>? map(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
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
      row['produtoNomeComercial'] ?? row['produtoNome'] ?? row['nomeComercial'] ?? row['nome'],
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

class DashboardFilterOption {
  const DashboardFilterOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class DashboardTableColumn {
  const DashboardTableColumn({
    required this.label,
    this.sortKey,
  });

  final String label;
  final String? sortKey;
}

List<DashboardFilterOption> dashboardUniqueOptions(
  Iterable<dynamic> values, {
  Map<String, String>? labels,
}) {
  final seen = <String>{};
  final items = <DashboardFilterOption>[];
  for (final value in values) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    items.add(
      DashboardFilterOption(
        value: normalized,
        label: labels?[normalized] ?? normalized,
      ),
    );
  }
  items.sort((a, b) => a.label.compareTo(b.label));
  return items;
}

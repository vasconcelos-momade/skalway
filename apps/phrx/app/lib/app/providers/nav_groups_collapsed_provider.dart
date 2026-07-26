import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_mode_provider.dart';

/// Títulos de grupos de menu colapsados (persistente).
///
/// O sidebar desktop é fixo — só os grupos (Vendas, Estoque, …) recolhem.
class NavGroupsCollapsedNotifier extends Notifier<Set<String>> {
  static const _key = 'nav_groups_collapsed';

  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  bool isCollapsed(String groupTitle) => state.contains(groupTitle);

  void toggle(String groupTitle) {
    final next = Set<String>.from(state);
    if (!next.add(groupTitle)) {
      next.remove(groupTitle);
    }
    _persist(next);
    state = next;
  }

  void setCollapsed(String groupTitle, bool collapsed) {
    final next = Set<String>.from(state);
    if (collapsed) {
      next.add(groupTitle);
    } else {
      next.remove(groupTitle);
    }
    if (next.length == state.length && next.containsAll(state)) return;
    _persist(next);
    state = next;
  }

  void _persist(Set<String> value) {
    ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode(value.toList(growable: false)),
        );
  }
}

final navGroupsCollapsedProvider =
    NotifierProvider<NavGroupsCollapsedNotifier, Set<String>>(
  NavGroupsCollapsedNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Títulos de grupos de menu expandidos (sessão atual).
class NavGroupsExpandedNotifier extends Notifier<Set<String>> {
  String? _lastActiveGroup;

  @override
  Set<String> build() {
    return <String>{};
  }

  /// Chamado sempre que a rota muda para expandir apenas o grupo ativo.
  void updateActiveGroup(String activeGroup) {
    if (_lastActiveGroup != activeGroup) {
      _lastActiveGroup = activeGroup;
      // Ao navegar para outro módulo, o grupo correspondente expande 
      // e os demais permanecem colapsados.
      state = {activeGroup};
    }
  }

  void toggle(String groupTitle) {
    final next = Set<String>.from(state);
    if (!next.add(groupTitle)) {
      next.remove(groupTitle);
    }
    state = next;
  }
}

final navGroupsExpandedProvider =
    NotifierProvider<NavGroupsExpandedNotifier, Set<String>>(
  NavGroupsExpandedNotifier.new,
);

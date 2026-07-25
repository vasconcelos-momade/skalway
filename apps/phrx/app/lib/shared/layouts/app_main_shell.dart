import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_layout.dart';

/// Ponto de entrada do shell principal (compatível com rotas existentes).
class AppMainShell extends ConsumerWidget {
  const AppMainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLayout(child: child);
  }
}

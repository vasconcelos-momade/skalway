import 'package:flutter/material.dart';

import 'pos_layout.dart';

/// Compat: delega para [PosLayout].
class PosShellLayout extends StatelessWidget {
  const PosShellLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PosLayout(child: child);
}

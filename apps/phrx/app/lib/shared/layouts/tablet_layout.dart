import 'package:flutter/material.dart';

/// Envolvimento touch-first para tablets — padding vem de [PharmaScreenLayout.pagePadding].
class TabletLayout extends StatelessWidget {
  const TabletLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

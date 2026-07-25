import 'package:flutter/material.dart';

import '../../estoque/presentation/pages/estoque_page.dart';

/// Gestão principal de stock farmacêutico — listagem consolidada de lotes.
class PharmacyStockHubPage extends StatelessWidget {
  const PharmacyStockHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return const EstoquePage();
  }
}

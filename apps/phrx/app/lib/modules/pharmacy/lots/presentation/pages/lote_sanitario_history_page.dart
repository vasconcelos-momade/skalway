import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/lote_sanitario_history_content.dart';

/// Página full-screen do histórico sanitário (mobile).
class LoteSanitarioHistoryPage extends ConsumerWidget {
  const LoteSanitarioHistoryPage({
    super.key,
    required this.loteId,
    this.numeroLote,
  });

  final String loteId;
  final String? numeroLote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Histórico • ${numeroLote ?? loteId}')),
      body: LoteSanitarioHistoryContent(
        loteId: loteId,
        numeroLote: numeroLote,
        showHeader: false,
      ),
    );
  }
}

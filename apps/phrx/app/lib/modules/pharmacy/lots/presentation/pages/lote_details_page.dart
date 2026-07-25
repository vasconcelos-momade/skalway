import 'package:flutter/material.dart';

import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../widgets/lote_details_content.dart';

/// Página full-screen de detalhe do lote (mobile, fora do [AppMainShell]).
class LoteDetailsPage extends StatefulWidget {
  const LoteDetailsPage({super.key, required this.loteId, this.title});

  final String loteId;
  final String? title;

  @override
  State<LoteDetailsPage> createState() => _LoteDetailsPageState();
}

class _LoteDetailsPageState extends State<LoteDetailsPage> {
  final _contentKey = GlobalKey<LoteDetailsContentState>();

  void _close() => AdaptiveNavigator.close(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Detalhe do lote'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => _contentKey.currentState?.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LoteDetailsContent(
        key: _contentKey,
        loteId: widget.loteId,
        embeddedInScaffold: true,
        onClose: _close,
      ),
    );
  }
}

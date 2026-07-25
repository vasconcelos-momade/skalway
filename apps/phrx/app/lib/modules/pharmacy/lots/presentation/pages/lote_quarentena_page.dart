import 'package:flutter/material.dart';

import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../models/lote_quarentena_form_data.dart';
import '../widgets/lote_quarentena_form_content.dart';

/// Página full-screen do formulário de quarentena (mobile).
class LoteQuarentenaPage extends StatelessWidget {
  const LoteQuarentenaPage({
    super.key,
    required this.lote,
    required this.isRevert,
  });

  final Map<String, dynamic> lote;
  final bool isRevert;

  num get _maxQuantidade {
    final field = isRevert ? 'quantidadeQuarentena' : 'quantidadeDisponivel';
    final value = lote[field];
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _close(BuildContext context, [LoteQuarentenaFormData? data]) {
    AdaptiveNavigator.complete(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRevert ? 'Reverter quarentena' : 'Mover para quarentena'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LoteQuarentenaFormContent(
          lote: lote,
          maxQuantidade: _maxQuantidade,
          isRevert: isRevert,
          onSubmit: (data) => _close(context, data),
          onCancel: () => _close(context),
        ),
      ),
    );
  }
}

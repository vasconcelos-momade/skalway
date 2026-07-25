import 'package:flutter/material.dart';

import '../models/lote_quarentena_form_data.dart';

/// Formulário de quarentena / liberação — desacoplado do container de apresentação.
class LoteQuarentenaFormContent extends StatefulWidget {
  const LoteQuarentenaFormContent({
    super.key,
    required this.lote,
    required this.maxQuantidade,
    required this.isRevert,
    required this.onSubmit,
    required this.onCancel,
  });

  final Map<String, dynamic> lote;
  final num maxQuantidade;
  final bool isRevert;
  final ValueChanged<LoteQuarentenaFormData> onSubmit;
  final VoidCallback onCancel;

  @override
  State<LoteQuarentenaFormContent> createState() =>
      _LoteQuarentenaFormContentState();
}

class _LoteQuarentenaFormContentState extends State<LoteQuarentenaFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyController;
  late final TextEditingController _motivoController;
  late final TextEditingController _docController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.maxQuantidade.toString(),
    );
    _motivoController = TextEditingController();
    _docController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _motivoController.dispose();
    _docController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final documento = _docController.text.trim();
    widget.onSubmit(
      LoteQuarentenaFormData(
        quantidade: num.parse(_qtyController.text.trim()),
        motivo: _motivoController.text.trim(),
        documentoReferencia: documento.isEmpty ? null : documento,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lote = widget.lote;
    final maxQty = widget.maxQuantidade;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isRevert
                ? 'Lote ${lote['numeroLote']} • em quarentena: $maxQty'
                : 'Lote ${lote['numeroLote']} • ${lote['produtoNomeComercial'] ?? lote['produtoNome'] ?? 'Produto'}',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _qtyController,
            decoration: InputDecoration(
              labelText: widget.isRevert
                  ? 'Quantidade a libertar'
                  : 'Quantidade',
              helperText: widget.isRevert
                  ? 'Máximo em quarentena: $maxQty'
                  : 'Máximo disponível: $maxQty',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final parsed = num.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Indique uma quantidade válida';
              }
              if (parsed > maxQty) {
                return widget.isRevert
                    ? 'Quantidade superior à quarentena actual'
                    : 'Quantidade superior ao stock disponível';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motivoController,
            decoration: InputDecoration(
              labelText: widget.isRevert ? 'Motivo da liberação' : 'Motivo',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if ((value?.trim().length ?? 0) < 3) {
                return 'Motivo obrigatório (mín. 3 caracteres)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _docController,
            decoration: const InputDecoration(
              labelText: 'Documento de referência (opcional)',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _submit, child: const Text('Continuar')),
            ],
          ),
        ],
      ),
    );
  }
}

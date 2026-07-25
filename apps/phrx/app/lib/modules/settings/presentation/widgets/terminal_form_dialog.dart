import 'package:flutter/material.dart';

import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/terminal.dart';

class TerminalFormResult {
  const TerminalFormResult({required this.payload});

  final Map<String, dynamic> payload;
}

Future<TerminalFormResult?> showTerminalFormDialog(
  BuildContext context, {
  TerminalDetalhe? terminal,
}) {
  return AdaptiveNavigator.openEmbeddedForm<TerminalFormResult>(
    context: context,
    title: Text(terminal == null ? 'Novo terminal' : 'Editar terminal'),
    routeSettings: RouteSettings(
      name: terminal == null ? '/terminais/novo' : '/terminais/${terminal.id}',
    ),
    formBuilder: (ctx, {required embedded}) =>
        _TerminalFormDialog(terminal: terminal, embedded: embedded),
  );
}

class _TerminalFormDialog extends StatefulWidget {
  const _TerminalFormDialog({this.terminal, this.embedded = false});

  final TerminalDetalhe? terminal;
  final bool embedded;

  @override
  State<_TerminalFormDialog> createState() => _TerminalFormDialogState();
}

class _TerminalFormDialogState extends State<_TerminalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nome;
  late final TextEditingController _localizacao;
  late bool _ativo;

  @override
  void initState() {
    super.initState();
    final terminal = widget.terminal;
    _codigo = TextEditingController(text: terminal?.codigo ?? '');
    _nome = TextEditingController(text: terminal?.nome ?? '');
    _localizacao = TextEditingController(text: terminal?.localizacao ?? '');
    _ativo = terminal?.ativo ?? true;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nome.dispose();
    _localizacao.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    AdaptiveNavigator.complete(
      context,
      TerminalFormResult(
        payload: <String, dynamic>{
          'codigo': _codigo.text.trim(),
          'nome': _nome.text.trim(),
          if (_localizacao.text.trim().isNotEmpty)
            'localizacao': _localizacao.text.trim(),
          'ativo': _ativo,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.terminal != null;
    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codigo,
            decoration: const InputDecoration(labelText: 'Código *'),
            textCapitalization: TextCapitalization.characters,
            enabled: !isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Código é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome *'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _localizacao,
            decoration: const InputDecoration(labelText: 'Localização'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activo'),
            value: _ativo,
            onChanged: (value) => setState(() => _ativo = value),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return PharmaResponsiveDialog(
        title: Text(isEditing ? 'Editar terminal' : 'Novo terminal'),
        content: content,
        actions: [
          TextButton(
            onPressed: () => AdaptiveNavigator.complete(context, null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Guardar' : 'Criar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(isEditing ? 'Editar terminal' : 'Novo terminal'),
      content: SizedBox(width: 420, child: content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Guardar' : 'Criar'),
        ),
      ],
    );
  }
}

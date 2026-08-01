import 'package:flutter/material.dart';

import '../../../../core/theme/extensions.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/terminal.dart';

class TerminalFormResult {
  const TerminalFormResult({required this.payload});

  final Map<String, dynamic> payload;
}

Future<TerminalFormResult?> showTerminalFormDialog(
  BuildContext context, {
  TerminalDetalhe? terminal,
}) {
  final title = Text(terminal == null ? 'Novo terminal' : 'Editar terminal');

  return AdaptiveNavigator.openPanel<TerminalFormResult>(
    context: context,
    routeSettings: RouteSettings(
      name: terminal == null ? '/terminais/novo' : '/terminais/${terminal.id}',
    ),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: SafeArea(
            child: _TerminalFormDialog(terminal: terminal, embedded: true),
          ),
        );
      }
      return _TerminalFormDialog(
        terminal: terminal,
        embedded: true,
        showHeader: true,
        onClose: () => AdaptiveNavigator.cancel(detailContext),
      );
    },
  );
}

class _TerminalFormDialog extends StatefulWidget {
  const _TerminalFormDialog({
    this.terminal,
    this.embedded = false,
    this.showHeader = false,
    this.onClose,
  });

  final TerminalDetalhe? terminal;
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onClose;

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
    final s = context.spacing;

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseTextFormField(
            controller: _codigo,
            labelText: 'Código *',
            textCapitalization: TextCapitalization.characters,
            enabled: !isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Código é obrigatório';
              }
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _nome,
            labelText: 'Nome *',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome é obrigatório';
              }
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _localizacao,
            labelText: 'Localização',
          ),
          SizedBox(height: s.md),
          EnterpriseFormSwitch(
            label: 'Activo',
            value: _ativo,
            onChanged: (value) => setState(() => _ativo = value),
          ),
        ],
      ),
    );

    final actions = [
      EnterpriseOverlayActions.secondary(
        label: 'Cancelar',
        onPressed: () => AdaptiveNavigator.cancel(context),
      ),
      EnterpriseOverlayActions.primary(
        label: isEditing ? 'Guardar' : 'Criar',
        onPressed: _submit,
      ),
    ];

    if (widget.embedded) {
      if (widget.showHeader) {
        return EnterpriseFormSideSheet(
          title: Text(isEditing ? 'Editar terminal' : 'Novo terminal'),
          onClose: widget.onClose,
          body: form,
          actions: actions,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(s.lg),
              child: form,
            ),
          ),
          EnterpriseOverlayFooter(actions: actions, expandOnNarrow: false),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(isEditing ? 'Editar terminal' : 'Novo terminal'),
      content: SizedBox(width: 420, child: form),
      actions: actions,
    );
  }
}

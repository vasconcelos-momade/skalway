import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/fornecedor.dart';

class FornecedorFormResult {
  const FornecedorFormResult({required this.payload});

  final Map<String, dynamic> payload;
}

Future<FornecedorFormResult?> showFornecedorFormDialog(
  BuildContext context, {
  FornecedorDetalhe? fornecedor,
}) {
  final title = Text(fornecedor == null ? 'Novo fornecedor' : 'Editar fornecedor');

  return AdaptiveNavigator.openPanel<FornecedorFormResult>(
    context: context,
    routeSettings: RouteSettings(
      name: fornecedor == null
          ? '/fornecedores/novo'
          : '/fornecedores/${fornecedor.id}',
    ),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: SafeArea(
            child: _FornecedorFormDialog(
              fornecedor: fornecedor,
              embedded: true,
            ),
          ),
        );
      }
      return _FornecedorFormDialog(
        fornecedor: fornecedor,
        embedded: true,
        showHeader: true,
        onClose: () => AdaptiveNavigator.cancel(detailContext),
      );
    },
  );
}

class _FornecedorFormDialog extends StatefulWidget {
  const _FornecedorFormDialog({
    this.fornecedor,
    this.embedded = false,
    this.showHeader = false,
    this.onClose,
  });

  final FornecedorDetalhe? fornecedor;
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  State<_FornecedorFormDialog> createState() => _FornecedorFormDialogState();
}

class _FornecedorFormDialogState extends State<_FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _nuit;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _cidade;
  late final TextEditingController _contato;

  @override
  void initState() {
    super.initState();
    final f = widget.fornecedor;
    _nome = TextEditingController(text: f?.nome ?? '');
    _nuit = TextEditingController(text: f?.nuit ?? '');
    _email = TextEditingController(text: f?.email ?? '');
    _telefone = TextEditingController(text: f?.telefone ?? '');
    _cidade = TextEditingController(text: f?.cidade ?? '');
    _contato = TextEditingController(text: f?.contatoNome ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _nuit.dispose();
    _email.dispose();
    _telefone.dispose();
    _cidade.dispose();
    _contato.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    AdaptiveNavigator.complete(
      context,
      FornecedorFormResult(
        payload: <String, dynamic>{
          'nome': _nome.text.trim(),
          if (_nuit.text.trim().isNotEmpty) 'nuit': _nuit.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
          if (_telefone.text.trim().isNotEmpty) 'telefone': _telefone.text.trim(),
          if (_cidade.text.trim().isNotEmpty) 'cidade': _cidade.text.trim(),
          if (_contato.text.trim().isNotEmpty) 'contatoNome': _contato.text.trim(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    final fields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnterpriseTextFormField(
          controller: _nome,
          labelText: 'Nome',
          validator: (value) =>
              value == null || value.trim().length < 2 ? 'Nome obrigatório' : null,
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(controller: _nuit, labelText: 'NUIT'),
        SizedBox(height: s.md),
        EnterpriseTextFormField(controller: _email, labelText: 'Email'),
        SizedBox(height: s.md),
        EnterpriseTextFormField(controller: _telefone, labelText: 'Telefone'),
        SizedBox(height: s.md),
        EnterpriseTextFormField(controller: _cidade, labelText: 'Cidade'),
        SizedBox(height: s.md),
        EnterpriseTextFormField(controller: _contato, labelText: 'Contacto'),
      ],
    );

    final actions = [
      EnterpriseOverlayActions.secondary(
        label: 'Cancelar',
        onPressed: () => AdaptiveNavigator.cancel(context),
      ),
      EnterpriseOverlayActions.primary(
        label: widget.fornecedor == null ? 'Criar' : 'Guardar',
        onPressed: _submit,
      ),
    ];

    final form = Form(key: _formKey, child: fields);

    if (widget.embedded) {
      if (widget.showHeader) {
        return EnterpriseFormSideSheet(
          title: Text(
            widget.fornecedor == null ? 'Novo fornecedor' : 'Editar fornecedor',
          ),
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
      title: Text(
        widget.fornecedor == null ? 'Novo fornecedor' : 'Editar fornecedor',
      ),
      content: form,
      actions: actions,
    );
  }
}

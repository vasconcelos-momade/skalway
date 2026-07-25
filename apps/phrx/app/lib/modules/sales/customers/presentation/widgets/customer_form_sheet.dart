import 'package:flutter/material.dart';

import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';
import '../../../../../core/theme/extensions.dart';
import '../../domain/entities/customer.dart';

class CustomerFormResult {
  const CustomerFormResult({
    required this.nome,
    required this.tipo,
    this.telefone,
    this.email,
    this.documento,
    this.nuit,
    this.endereco,
    this.limiteCredito,
    this.temPrescricao = false,
    this.version,
  });

  final String nome;
  final String tipo;
  final String? telefone;
  final String? email;
  final String? documento;
  final String? nuit;
  final String? endereco;
  final double? limiteCredito;
  final bool temPrescricao;
  final int? version;

  CustomerFormPayload toPayload() => CustomerFormPayload(
        nome: nome,
        tipo: tipo,
        telefone: telefone,
        email: email,
        documento: documento,
        nuit: nuit,
        endereco: endereco,
        limiteCredito: limiteCredito,
        temPrescricao: temPrescricao,
        version: version,
      );
}

Future<CustomerFormResult?> showCustomerFormSheet(
  BuildContext context, {
  CustomerDetail? customer,
}) {
  return AdaptiveSideSheet.show<CustomerFormResult>(
    context: context,
    builder: (sheetContext) {
      final s = sheetContext.spacing;
      final titleText = customer != null ? 'Editar cliente' : 'Novo cliente';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.sm, s.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => closeAdaptiveSideSheet(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomerForm(customer: customer),
          ),
        ],
      );
    },
  );
}

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key, this.customer});

  final CustomerDetail? customer;

  bool get isEditing => customer != null;

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _documentoController;
  late final TextEditingController _nuitController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _limiteController;
  late String _tipo;
  late bool _temPrescricao;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nomeController = TextEditingController(text: c?.nome ?? '');
    _telefoneController = TextEditingController(text: c?.telefone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _documentoController = TextEditingController(text: c?.documento ?? '');
    _nuitController = TextEditingController(text: c?.nuit ?? '');
    _enderecoController = TextEditingController(text: c?.endereco ?? '');
    _limiteController = TextEditingController(
      text: c?.limiteCredito != null ? c!.limiteCredito!.toString() : '',
    );
    _tipo = c?.tipo ?? 'PACIENTE';
    _temPrescricao = c?.temPrescricao ?? false;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _nuitController.dispose();
    _enderecoController.dispose();
    _limiteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final limiteText = _limiteController.text.trim();
    final limite = limiteText.isEmpty
        ? null
        : double.tryParse(limiteText.replaceAll(',', '.'));

    AdaptiveNavigator.complete(
      context,
      CustomerFormResult(
        nome: _nomeController.text.trim(),
        tipo: _tipo,
        telefone: _telefoneController.text.trim(),
        email: _emailController.text.trim(),
        documento: _documentoController.text.trim(),
        nuit: _nuitController.text.trim(),
        endereco: _enderecoController.text.trim(),
        limiteCredito: limite,
        temPrescricao: _temPrescricao,
        version: widget.customer?.version,
      ),
    );
  }

  Widget _buildFormBody(BuildContext context) {
    final s = context.spacing;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
          ),
          SizedBox(height: s.md),
          DropdownButtonFormField<String>(
            initialValue: _tipo,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'PACIENTE', child: Text('Paciente')),
              DropdownMenuItem(value: 'EMPRESA', child: Text('Empresa')),
              DropdownMenuItem(value: 'CONVENIO', child: Text('Convénio')),
            ],
            onChanged: (v) => setState(() => _tipo = v ?? 'PACIENTE'),
          ),
          SizedBox(height: s.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _telefoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: TextFormField(
                  controller: _nuitController,
                  decoration: const InputDecoration(
                    labelText: 'NUIT',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _documentoController,
            decoration: const InputDecoration(
              labelText: 'Documento',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _enderecoController,
            decoration: const InputDecoration(
              labelText: 'Endereço',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _limiteController,
            decoration: const InputDecoration(
              labelText: 'Limite de crédito (MT)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: s.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tem prescrição'),
            value: _temPrescricao,
            onChanged: (v) => setState(() => _temPrescricao = v),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(s.lg),
            child: _buildFormBody(context),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(s.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => closeAdaptiveSideSheet(context),
                child: const Text('Cancelar'),
              ),
              SizedBox(width: s.sm),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.isEditing ? 'Guardar' : 'Criar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/platform_entities.dart';

class RegisterTenantFormResult {
  const RegisterTenantFormResult({required this.payload});

  final RegisterTenantPayload payload;
}

Future<RegisterTenantFormResult?> showRegisterTenantFormDialog(
  BuildContext context,
) {
  return AdaptiveNavigator.openEmbeddedForm<RegisterTenantFormResult>(
    context: context,
    title: const Text('Novo cliente'),
    routeSettings: const RouteSettings(name: '/platform/tenants/novo'),
    sideSheetWidth: 560,
    formBuilder: (ctx, {required embedded}) =>
        RegisterTenantFormDialog(embedded: embedded),
  );
}

class RegisterTenantFormDialog extends StatefulWidget {
  const RegisterTenantFormDialog({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RegisterTenantFormDialog> createState() =>
      _RegisterTenantFormDialogState();
}

class _RegisterTenantFormDialogState extends State<RegisterTenantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _empresaCtrl = TextEditingController();
  final _tenantCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPassCtrl = TextEditingController();

  @override
  void dispose() {
    _empresaCtrl.dispose();
    _tenantCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _ownerPassCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final payload = RegisterTenantPayload(
      nomeEmpresa: _empresaCtrl.text.trim(),
      nomeTenant: _tenantCtrl.text.trim(),
      adminName: _adminNameCtrl.text.trim(),
      adminEmail: _adminEmailCtrl.text.trim(),
      adminPassword: _adminPassCtrl.text,
      ownerName: _ownerNameCtrl.text.trim(),
      ownerEmail: _ownerEmailCtrl.text.trim(),
      ownerPassword: _ownerPassCtrl.text,
    );
    AdaptiveNavigator.complete(
      context,
      RegisterTenantFormResult(payload: payload),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool email = false,
    bool obscure = false,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        validator: validator ??
            (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
              if (email && !v.contains('@')) return 'E-mail inválido';
              if (obscure && v.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Empresa / Tenant',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _field(label: 'Nome da empresa', controller: _empresaCtrl),
          _field(
            label: 'Identificador do tenant',
            controller: _tenantCtrl,
            hint: 'ex: farmacia_demo',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Administrador local (tenant)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _field(label: 'Nome', controller: _adminNameCtrl),
          _field(label: 'E-mail', controller: _adminEmailCtrl, email: true),
          _field(
            label: 'Palavra-passe',
            controller: _adminPassCtrl,
            obscure: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Dono (conta central)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _field(label: 'Nome', controller: _ownerNameCtrl),
          _field(label: 'E-mail', controller: _ownerEmailCtrl, email: true),
          _field(
            label: 'Palavra-passe',
            controller: _ownerPassCtrl,
            obscure: true,
          ),
        ],
      ),
    );
  }

  List<Widget> _actions() => [
        TextButton(
          onPressed: () => AdaptiveNavigator.cancel(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Criar cliente'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBody(),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: _actions()),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: const Text('Novo cliente'),
      content: _buildBody(),
      actions: _actions(),
    );
  }
}

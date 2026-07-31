import 'package:flutter/material.dart';

import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';
import '../../domain/entities/user_entities.dart';

class UserFormResult {
  const UserFormResult({
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
    this.version,
  });

  final String name;
  final String email;
  final String role;
  final bool active;
  final int? version;

  UserFormPayload toPayload() => UserFormPayload(
        name: name,
        email: email,
        role: role,
        active: active,
        version: version,
      );
}

Future<UserFormResult?> showUserFormDialog(
  BuildContext context, {
  TenantUserDetail? user,
}) {
  final titleText = user != null ? 'Editar utilizador' : 'Novo utilizador';
  final width = AdaptiveNavigator.widthOf(context);
  final panelWidth =
      width >= AdaptiveSideSheetMetrics.desktopBreakpoint ? 520.0 : 480.0;

  return AdaptiveNavigator.openPanel<UserFormResult>(
    context: context,
    sideSheetWidth: panelWidth,
    routeSettings: RouteSettings(
      name: user == null ? '/utilizadores/novo' : '/utilizadores/${user.id}/editar',
    ),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return Scaffold(
          appBar: AppBar(title: Text(titleText)),
          body: SafeArea(
            child: UserFormDialog(
              user: user,
              embedded: true,
            ),
          ),
        );
      }
      return UserFormDialog(
        user: user,
        embedded: true,
        showHeader: true,
        onClose: () => AdaptiveNavigator.cancel(detailContext),
      );
    },
  );
}

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({
    super.key,
    this.user,
    this.embedded = false,
    this.showHeader = false,
    this.onClose,
  });

  final TenantUserDetail? user;
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onClose;

  bool get isEditing => user != null;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _role;
  late bool _active;

  static const _roles = [
    ('ADMIN', 'Administrador'),
    ('GERENTE', 'Gestor'),
    ('FARMACEUTICO', 'Farmacêutico'),
    ('DIRETOR_TECNICO', 'Director técnico'),
    ('CAIXA', 'Caixa PDV'),
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u?.name ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _role = u?.role ?? 'GERENTE';
    _active = u?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AdaptiveNavigator.complete(
      context,
      UserFormResult(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        active: _active,
        version: widget.user?.version,
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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome *',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
          ),
          SizedBox(height: s.md),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email obrigatório';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseSelectFormField<String>(
            label: 'Perfil',
            initialValue: _role,
            options: [
              for (final role in _roles)
                EnterpriseSelectOption<String>(
                  value: role.$1,
                  label: role.$2,
                ),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'GERENTE'),
          ),
          SizedBox(height: s.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Utilizador activo'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() => [
        TextButton(
          onPressed: () => AdaptiveNavigator.cancel(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isEditing ? 'Guardar' : 'Criar'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      final isMobile = AdaptiveNavigator.isMobile(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEditing ? 'Editar utilizador' : 'Novo utilizador',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: _buildFormBody(context),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActions(),
            ),
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(widget.isEditing ? 'Editar utilizador' : 'Novo utilizador'),
      content: _buildFormBody(context),
      actions: _buildActions(),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
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

  return AdaptiveNavigator.openPanel<UserFormResult>(
    context: context,
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
          EnterpriseTextFormField(
            controller: _nameController,
            labelText: 'Nome *',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _emailController,
            labelText: 'Email *',
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
          EnterpriseFormSwitch(
            label: 'Utilizador activo',
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() => [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: () => AdaptiveNavigator.cancel(context),
        ),
        EnterpriseOverlayActions.primary(
          label: widget.isEditing ? 'Guardar' : 'Criar',
          onPressed: _submit,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      if (widget.showHeader) {
        return EnterpriseFormSideSheet(
          title: Text(
            widget.isEditing ? 'Editar utilizador' : 'Novo utilizador',
          ),
          onClose: widget.onClose,
          body: _buildFormBody(context),
          actions: _buildActions(),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.spacing.lg),
              child: _buildFormBody(context),
            ),
          ),
          EnterpriseOverlayFooter(
            actions: _buildActions(),
            expandOnNarrow: false,
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

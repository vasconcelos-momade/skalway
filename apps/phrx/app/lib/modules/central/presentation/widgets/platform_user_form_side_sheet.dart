import 'package:flutter/material.dart';

import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/enterprise_side_sheet.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/platform_entities.dart';

Future<PlatformUserPayload?> showPlatformUserFormSideSheet(
  BuildContext context, {
  PlatformUser? user,
  bool resetPasswordOnly = false,
}) {
  return EnterpriseSideSheet.show<PlatformUserPayload>(
    context: context,
    barrierDismissible: false,
    builder: (sheetContext) => PlatformUserFormSideSheet(
      user: user,
      resetPasswordOnly: resetPasswordOnly,
    ),
  );
}

class PlatformUserFormSideSheet extends StatefulWidget {
  const PlatformUserFormSideSheet({
    super.key,
    this.user,
    this.resetPasswordOnly = false,
  });

  final PlatformUser? user;
  final bool resetPasswordOnly;

  bool get isEditing => user != null;

  @override
  State<PlatformUserFormSideSheet> createState() =>
      _PlatformUserFormSideSheetState();
}

class _PlatformUserFormSideSheetState extends State<PlatformUserFormSideSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirm;
  late String _role;
  late bool _active;
  bool _obscure = true;

  static const _roles = <(String, String)>[
    ('superadmin', 'SuperAdmin'),
    ('admin', 'Admin'),
    ('usuario', 'Utilizador'),
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _password = TextEditingController();
    _confirm = TextEditingController();
    _role = u?.role ?? 'superadmin';
    _active = u?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.resetPasswordOnly) {
      closeEnterpriseSideSheet(
        context,
        PlatformUserPayload(
          name: widget.user!.name,
          email: widget.user!.email,
          role: widget.user!.role,
          password: _password.text,
          active: widget.user!.active,
        ),
      );
      return;
    }

    closeEnterpriseSideSheet(
      context,
      PlatformUserPayload(
        name: _name.text.trim(),
        email: _email.text.trim().toLowerCase(),
        role: _role,
        password: _password.text.isEmpty ? null : _password.text,
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final isReset = widget.resetPasswordOnly;
    final requirePassword = !widget.isEditing || isReset;

    final body = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isReset) ...[
            EnterpriseTextFormField(
              controller: _name,
              labelText: 'Nome *',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            SizedBox(height: s.md),
            EnterpriseTextFormField(
              controller: _email,
              labelText: 'Email *',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Obrigatório';
                if (!value.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            SizedBox(height: s.md),
            EnterpriseSelectField<String>(
              label: 'Perfil',
              value: _role,
              options: [
                for (final role in _roles)
                  EnterpriseSelectOption(value: role.$1, label: role.$2),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
            SizedBox(height: s.md),
            EnterpriseFormSwitch(
              label: 'Activo',
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            SizedBox(height: s.md),
          ],
          EnterpriseTextFormField(
            controller: _password,
            labelText: requirePassword
                ? 'Password *'
                : 'Password (deixar vazio para manter)',
            obscureText: _obscure,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (v) {
              final value = v ?? '';
              if (!requirePassword && value.isEmpty) return null;
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          if (requirePassword || _password.text.isNotEmpty) ...[
            SizedBox(height: s.md),
            EnterpriseTextFormField(
              controller: _confirm,
              labelText: 'Confirmar Password *',
              obscureText: _obscure,
              validator: (v) {
                if ((v ?? '') != _password.text) {
                  return 'As passwords não coincidem';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );

    return EnterpriseFormSideSheet(
      title: Text(
        isReset
            ? 'Reset Password'
            : widget.isEditing
                ? 'Editar Utilizador'
                : 'Criar Utilizador',
      ),
      onClose: () => closeEnterpriseSideSheet(context),
      body: body,
      actions: [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: () => closeEnterpriseSideSheet(context),
        ),
        EnterpriseOverlayActions.primary(
          label: isReset
              ? 'Redefinir'
              : widget.isEditing
                  ? 'Guardar'
                  : 'Criar',
          onPressed: _submit,
        ),
      ],
    );
  }
}

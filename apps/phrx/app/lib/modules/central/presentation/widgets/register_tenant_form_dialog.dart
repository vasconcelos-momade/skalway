import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_tokens.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

class RegisterTenantFormResult {
  const RegisterTenantFormResult({
    required this.payload,
    this.created,
  });

  final RegisterTenantPayload payload;
  final RegisterTenantResult? created;
}

Future<RegisterTenantFormResult?> showRegisterTenantFormDialog(
  BuildContext context,
) {
  return AdaptiveNavigator.openEmbeddedForm<RegisterTenantFormResult>(
    context: context,
    title: const Text('Novo cliente'),
    routeSettings: const RouteSettings(name: '/platform/tenants/novo'),
    size: EnterpriseOverlaySize.large,
    barrierDismissible: false,
    forceSideSheet: true,
    formBuilder: (ctx, {required embedded}) =>
        RegisterTenantFormDialog(embedded: embedded),
  );
}

String normalizeTenantSlug(String raw) {
  final normalized = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (normalized.length <= 48) return normalized;
  return normalized.substring(0, 48);
}

bool isValidNuit(String value) =>
    RegExp(r'^\d{9}$').hasMatch(value.replaceAll(RegExp(r'\s+'), ''));

class RegisterTenantFormDialog extends ConsumerStatefulWidget {
  const RegisterTenantFormDialog({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<RegisterTenantFormDialog> createState() =>
      _RegisterTenantFormDialogState();
}

class _RegisterTenantFormDialogState
    extends ConsumerState<RegisterTenantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _empresaCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nuitCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController(text: 'Matriz');
  final _branchEnderecoCtrl = TextEditingController();
  final _branchContactoCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPassCtrl = TextEditingController();

  String _planSlug = 'starter';
  String _status = 'trial';
  bool _slugManual = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _empresaCtrl.addListener(_onEmpresaChanged);
  }

  void _onEmpresaChanged() {
    if (_slugManual || _submitting) return;
    final next = normalizeTenantSlug(_empresaCtrl.text);
    if (_slugCtrl.text != next) {
      _slugCtrl.text = next;
    }
  }

  @override
  void dispose() {
    _empresaCtrl.removeListener(_onEmpresaChanged);
    _empresaCtrl.dispose();
    _slugCtrl.dispose();
    _emailCtrl.dispose();
    _nuitCtrl.dispose();
    _enderecoCtrl.dispose();
    _telefoneCtrl.dispose();
    _branchNameCtrl.dispose();
    _branchEnderecoCtrl.dispose();
    _branchContactoCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _ownerPassCtrl.dispose();
    super.dispose();
  }

  RegisterTenantPayload _buildPayload() {
    final slug = normalizeTenantSlug(_slugCtrl.text);
    final branchName = _branchNameCtrl.text.trim().isEmpty
        ? '${_empresaCtrl.text.trim()} - Matriz'
        : _branchNameCtrl.text.trim();

    return RegisterTenantPayload(
      nomeEmpresa: _empresaCtrl.text.trim(),
      nomeTenant: slug,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      endereco:
          _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      nuit: _nuitCtrl.text.trim().isEmpty ? null : _nuitCtrl.text.trim(),
      telefone:
          _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      planSlug: _planSlug,
      status: _status,
      branchName: branchName,
      branchEndereco: _branchEnderecoCtrl.text.trim().isEmpty
          ? null
          : _branchEnderecoCtrl.text.trim(),
      branchContacto: _branchContactoCtrl.text.trim().isEmpty
          ? null
          : _branchContactoCtrl.text.trim(),
      adminName: _adminNameCtrl.text.trim(),
      adminEmail: _adminEmailCtrl.text.trim(),
      adminPassword: _adminPassCtrl.text,
      ownerName: _ownerNameCtrl.text.trim(),
      ownerEmail: _ownerEmailCtrl.text.trim(),
      ownerPassword: _ownerPassCtrl.text,
    );
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildPayload();
    setState(() => _submitting = true);

    try {
      final created = await ref
          .read(platformBillingActionsProvider.notifier)
          .registerTenant(payload);
      if (!mounted) return;
      AdaptiveNavigator.complete(
        context,
        RegisterTenantFormResult(payload: payload, created: created),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiFailure
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _submitting = false;
        _errorMessage = message;
      });
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool email = false,
    bool obscure = false,
    bool enabled = true,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        enabled: enabled && !_submitting,
        obscureText: obscure,
        onChanged: onChanged,
        keyboardType: keyboardType ??
            (email ? TextInputType.emailAddress : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        validator: validator ??
            (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
              if (email && !v.contains('@')) return 'E-mail inválido';
              if (obscure && v.length < 6) return 'Mínimo 6 caracteres';
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
          if (_errorMessage != null) ...[
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_submitting) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A provisionar cliente (base de dados, migrations e configuração inicial). Isto pode demorar alguns minutos…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _sectionTitle('Empresa'),
          _field(label: 'Nome da empresa *', controller: _empresaCtrl),
          _field(
            label: 'NUIT *',
            controller: _nuitCtrl,
            keyboardType: TextInputType.number,
            hint: '9 dígitos',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
              if (!isValidNuit(v)) return 'NUIT inválido (9 dígitos)';
              return null;
            },
          ),
          _field(
            label: 'E-mail da empresa *',
            controller: _emailCtrl,
            email: true,
          ),
          _field(label: 'Endereço *', controller: _enderecoCtrl),
          _field(
            label: 'Telefone',
            controller: _telefoneCtrl,
            keyboardType: TextInputType.phone,
            validator: (_) => null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _sectionTitle('Tenant / subscrição'),
          _field(
            label: 'Slug / identificador *',
            controller: _slugCtrl,
            hint: 'ex: farmacia_maputo',
            onChanged: (_) => _slugManual = true,
            validator: (v) {
              final slug = normalizeTenantSlug(v ?? '');
              if (slug.length < 2) {
                return 'Slug inválido (mín. 2 caracteres)';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use — controlled dropdown; initialValue is for uncontrolled fields
              value: _planSlug,
              decoration: const InputDecoration(labelText: 'Plano inicial *'),
              items: const [
                DropdownMenuItem(value: 'starter', child: Text('Starter')),
                DropdownMenuItem(
                  value: 'enterprise',
                  child: Text('Enterprise'),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _planSlug = v ?? 'starter'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use — controlled dropdown; initialValue is for uncontrolled fields
              value: _status,
              decoration: const InputDecoration(labelText: 'Estado inicial *'),
              items: const [
                DropdownMenuItem(value: 'trial', child: Text('Trial')),
                DropdownMenuItem(value: 'ativo', child: Text('Activo')),
              ],
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _status = v ?? 'trial'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _sectionTitle('Filial principal'),
          _field(label: 'Nome da filial *', controller: _branchNameCtrl),
          _field(
            label: 'Endereço da filial',
            controller: _branchEnderecoCtrl,
            validator: (_) => null,
          ),
          _field(
            label: 'Contacto da filial',
            controller: _branchContactoCtrl,
            validator: (_) => null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _sectionTitle('Administrador local (tenant)'),
          _field(label: 'Nome *', controller: _adminNameCtrl),
          _field(label: 'E-mail *', controller: _adminEmailCtrl, email: true),
          _field(
            label: 'Palavra-passe *',
            controller: _adminPassCtrl,
            obscure: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _sectionTitle('Dono (conta central)'),
          _field(label: 'Nome *', controller: _ownerNameCtrl),
          _field(label: 'E-mail *', controller: _ownerEmailCtrl, email: true),
          _field(
            label: 'Palavra-passe *',
            controller: _ownerPassCtrl,
            obscure: true,
          ),
        ],
      ),
    );
  }

  List<Widget> _actions() => [
        TextButton(
          onPressed: _submitting ? null : () => AdaptiveNavigator.cancel(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar cliente'),
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

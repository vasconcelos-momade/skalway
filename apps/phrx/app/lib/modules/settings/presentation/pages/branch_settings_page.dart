import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/inputs/enterprise_form_grid.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../data/models/branch_settings_model.dart';
import '../../domain/branch_setting_keys.dart';
import '../providers/branch_settings_provider.dart';

/// Configurações da filial activa (BranchSetting).
/// Separado de Sistema / CentralSettings / TenantSetting.
class BranchSettingsPage extends ConsumerStatefulWidget {
  const BranchSettingsPage({super.key});

  @override
  ConsumerState<BranchSettingsPage> createState() => _BranchSettingsPageState();
}

class _BranchSettingsPageState extends ConsumerState<BranchSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _endereco = TextEditingController();
  final _cidade = TextEditingController();
  final _provincia = TextEditingController();
  final _nomeLegal = TextEditingController();
  final _nuit = TextEditingController();
  final _regimeFiscal = TextEditingController();
  final _nomeExibido = TextEditingController();
  final _logo = TextEditingController();
  final _footer = TextEditingController();
  final _moeda = TextEditingController();
  final _impressaoTipo = TextEditingController();
  final _larguraPapel = TextEditingController();
  final _printerPadrao = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  bool _hydrated = false;
  bool _iva = true;
  String? _hydratedBranchId;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _email.dispose();
    _telefone.dispose();
    _endereco.dispose();
    _cidade.dispose();
    _provincia.dispose();
    _nomeLegal.dispose();
    _nuit.dispose();
    _regimeFiscal.dispose();
    _nomeExibido.dispose();
    _logo.dispose();
    _footer.dispose();
    _moeda.dispose();
    _impressaoTipo.dispose();
    _larguraPapel.dispose();
    _printerPadrao.dispose();
    super.dispose();
  }

  void _hydrate(BranchSettingsSnapshot data) {
    if (_hydrated && _hydratedBranchId == data.branchId && _editing) return;
    _name.text = data.text(BranchSettingKeys.name);
    _code.text = data.text(BranchSettingKeys.code).isNotEmpty
        ? data.text(BranchSettingKeys.code)
        : (data.branchCode ?? '');
    _email.text = data.text(BranchSettingKeys.email);
    _telefone.text = data.text(BranchSettingKeys.telefone);
    _endereco.text = data.text(BranchSettingKeys.endereco);
    _cidade.text = data.text(BranchSettingKeys.cidade);
    _provincia.text = data.text(BranchSettingKeys.provincia);
    _nomeLegal.text = data.text(BranchSettingKeys.nomeLegal);
    _nuit.text = data.text(BranchSettingKeys.nuit);
    _regimeFiscal.text = data.text(BranchSettingKeys.regimeFiscal);
    _nomeExibido.text = data.text(BranchSettingKeys.nomeExibido);
    _logo.text = data.text(BranchSettingKeys.logo);
    _footer.text = data.text(BranchSettingKeys.footer);
    _moeda.text = data.text(BranchSettingKeys.moeda);
    _impressaoTipo.text = data.text(BranchSettingKeys.impressaoTipo);
    final largura = data.intValue(BranchSettingKeys.larguraPapel);
    _larguraPapel.text = largura?.toString() ?? '';
    _printerPadrao.text = data.text(BranchSettingKeys.printerPadrao);
    _iva = data.boolValue(BranchSettingKeys.iva, fallback: true);
    _hydrated = true;
    _hydratedBranchId = data.branchId;
  }

  String? _nullable(String raw) {
    final text = raw.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final settings = <String, dynamic>{
        BranchSettingKeys.name: _name.text.trim(),
        BranchSettingKeys.email: _nullable(_email.text),
        BranchSettingKeys.telefone: _nullable(_telefone.text),
        BranchSettingKeys.endereco: _nullable(_endereco.text),
        BranchSettingKeys.cidade: _nullable(_cidade.text),
        BranchSettingKeys.provincia: _nullable(_provincia.text),
        BranchSettingKeys.nomeLegal: _nullable(_nomeLegal.text),
        BranchSettingKeys.nuit: _nullable(_nuit.text),
        BranchSettingKeys.regimeFiscal: _nullable(_regimeFiscal.text),
        BranchSettingKeys.iva: _iva,
        BranchSettingKeys.nomeExibido: _nullable(_nomeExibido.text),
        BranchSettingKeys.logo: _nullable(_logo.text),
        BranchSettingKeys.footer: _nullable(_footer.text),
        BranchSettingKeys.moeda: _nullable(_moeda.text) ?? 'MZN',
        BranchSettingKeys.impressaoTipo: _nullable(_impressaoTipo.text),
        BranchSettingKeys.larguraPapel:
            int.tryParse(_larguraPapel.text.trim()) ?? 80,
        BranchSettingKeys.printerPadrao: _nullable(_printerPadrao.text),
      };
      await ref.read(branchSettingsProvider.notifier).save(settings);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
        _hydrated = false;
      });
      PharmaFeedback.success(context, 'Configurações da filial guardadas.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is ApiFailure ? e.message : e.toString();
      PharmaFeedback.error(context, message);
    }
  }

  void _cancel(BranchSettingsSnapshot data) {
    setState(() {
      _editing = false;
      _hydrated = false;
    });
    _hydrate(data);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final async = ref.watch(branchSettingsProvider);
    final session = ref.watch(authSessionProvider).session;
    final branchLabel = session?.selectedBranch?.name ?? 'Filial activa';
    final fieldsEnabled = _editing && !_saving;

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final maxFormWidth = constraints.isTabletOrWider ? 920.0 : double.infinity;

        return EnterpriseModuleHub(
          title: 'Filial',
          subtitle:
              'Identidade, contacto, fiscal e documento da filial «$branchLabel».',
          tag: 'Filial',
          actions: [
            if (_editing)
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () {
                        final data = async.asData?.value;
                        if (data != null) _cancel(data);
                      },
                child: const Text('Cancelar'),
              ),
            FilledButton.icon(
              onPressed: async.isLoading || _saving
                  ? null
                  : () {
                      if (_editing) {
                        _save();
                      } else {
                        setState(() => _editing = true);
                      }
                    },
              icon: Icon(_editing ? Icons.save_outlined : Icons.edit_outlined),
              label: Text(
                _saving
                    ? 'A guardar…'
                    : _editing
                        ? 'Salvar'
                        : 'Editar',
              ),
            ),
          ],
          child: async.when(
            loading: () => const ModuleLoadingState(),
            error: (e, _) => ModuleErrorState(
              title: 'Erro ao carregar configurações da filial',
              message: e.toString(),
              onRetry: () =>
                  ref.read(branchSettingsProvider.notifier).refresh(),
            ),
            data: (data) {
              _hydrate(data);
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        _Section(
                          title: 'Identidade',
                          child: EnterpriseFormGrid(
                            gap: s.md,
                            children: [
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _name,
                                  labelText: 'Nome da filial *',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Obrigatório'
                                          : null,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _code,
                                  labelText: 'Código da filial',
                                  readOnly: true,
                                  enabled: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Section(
                          title: 'Contacto',
                          child: EnterpriseFormGrid(
                            gap: s.md,
                            children: [
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _email,
                                  labelText: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _telefone,
                                  labelText: 'Telefone',
                                  keyboardType: TextInputType.phone,
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                fullWidth: true,
                                child: EnterpriseTextFormField(
                                  controller: _endereco,
                                  labelText: 'Endereço',
                                  maxLines: 2,
                                  minLines: 2,
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _cidade,
                                  labelText: 'Cidade',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _provincia,
                                  labelText: 'Província',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Section(
                          title: 'Fiscal',
                          child: EnterpriseFormGrid(
                            gap: s.md,
                            children: [
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _nomeLegal,
                                  labelText: 'Nome legal',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _nuit,
                                  labelText: 'NUIT',
                                  keyboardType: TextInputType.number,
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _regimeFiscal,
                                  labelText: 'Regime fiscal',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('IVA activo'),
                                  value: _iva,
                                  onChanged: fieldsEnabled
                                      ? (v) => setState(() => _iva = v)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Section(
                          title: 'Documento',
                          child: EnterpriseFormGrid(
                            gap: s.md,
                            children: [
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _nomeExibido,
                                  labelText: 'Nome exibido na fatura',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _moeda,
                                  labelText: 'Moeda',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                fullWidth: true,
                                child: EnterpriseTextFormField(
                                  controller: _logo,
                                  labelText: 'Logo (URL ou caminho)',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                fullWidth: true,
                                child: EnterpriseTextFormField(
                                  controller: _footer,
                                  labelText: 'Footer da fatura',
                                  maxLines: 2,
                                  minLines: 2,
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Section(
                          title: 'Impressão',
                          child: EnterpriseFormGrid(
                            gap: s.md,
                            children: [
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _printerPadrao,
                                  labelText: 'Impressora padrão (id)',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _impressaoTipo,
                                  labelText: 'Tipo de impressão',
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                ),
                              ),
                              EnterpriseFormGridItem(
                                child: EnterpriseTextFormField(
                                  controller: _larguraPapel,
                                  labelText: 'Largura do papel (mm)',
                                  keyboardType: TextInputType.number,
                                  readOnly: !fieldsEnabled,
                                  enabled: fieldsEnabled,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: s.xl),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    return Padding(
      padding: EdgeInsets.only(bottom: s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: s.sm),
          child,
        ],
      ),
    );
  }
}

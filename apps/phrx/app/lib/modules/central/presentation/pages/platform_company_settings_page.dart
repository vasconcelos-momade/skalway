import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/inputs/enterprise_form_grid.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

/// Configurações institucionais da Central (singleton).
class PlatformCompanySettingsPage extends ConsumerStatefulWidget {
  const PlatformCompanySettingsPage({super.key});

  @override
  ConsumerState<PlatformCompanySettingsPage> createState() =>
      _PlatformCompanySettingsPageState();
}

class _PlatformCompanySettingsPageState
    extends ConsumerState<PlatformCompanySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  var _hydrated = false;
  var _editing = false;

  late final TextEditingController _companyName;
  late final TextEditingController _companyNuit;
  late final TextEditingController _companyEmail;
  late final TextEditingController _companyPhone;
  late final TextEditingController _companyAddress;
  late final TextEditingController _companyCity;
  late final TextEditingController _companyProvince;
  late final TextEditingController _companyCountry;
  late final TextEditingController _companyLogo;
  late final TextEditingController _mpesaName;
  late final TextEditingController _mpesaNumber;
  late final TextEditingController _emolaName;
  late final TextEditingController _emolaNumber;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccountName;
  late final TextEditingController _bankAccountNumber;
  late final TextEditingController _bankNib;
  late final TextEditingController _bankSwift;
  late final TextEditingController _bankInstructions;
  late final TextEditingController _invoiceFooter;
  late final TextEditingController _receiptFooter;
  late final TextEditingController _defaultMessage;

  @override
  void initState() {
    super.initState();
    _companyName = TextEditingController();
    _companyNuit = TextEditingController();
    _companyEmail = TextEditingController();
    _companyPhone = TextEditingController();
    _companyAddress = TextEditingController();
    _companyCity = TextEditingController();
    _companyProvince = TextEditingController();
    _companyCountry = TextEditingController(text: 'MZ');
    _companyLogo = TextEditingController();
    _mpesaName = TextEditingController();
    _mpesaNumber = TextEditingController();
    _emolaName = TextEditingController();
    _emolaNumber = TextEditingController();
    _bankName = TextEditingController();
    _bankAccountName = TextEditingController();
    _bankAccountNumber = TextEditingController();
    _bankNib = TextEditingController();
    _bankSwift = TextEditingController();
    _bankInstructions = TextEditingController();
    _invoiceFooter = TextEditingController();
    _receiptFooter = TextEditingController();
    _defaultMessage = TextEditingController();
  }

  @override
  void dispose() {
    _companyName.dispose();
    _companyNuit.dispose();
    _companyEmail.dispose();
    _companyPhone.dispose();
    _companyAddress.dispose();
    _companyCity.dispose();
    _companyProvince.dispose();
    _companyCountry.dispose();
    _companyLogo.dispose();
    _mpesaName.dispose();
    _mpesaNumber.dispose();
    _emolaName.dispose();
    _emolaNumber.dispose();
    _bankName.dispose();
    _bankAccountName.dispose();
    _bankAccountNumber.dispose();
    _bankNib.dispose();
    _bankSwift.dispose();
    _bankInstructions.dispose();
    _invoiceFooter.dispose();
    _receiptFooter.dispose();
    _defaultMessage.dispose();
    super.dispose();
  }

  void _hydrate(PlatformCentralSettings s) {
    if (_hydrated) return;
    _hydrated = true;
    _companyName.text = s.companyName;
    _companyNuit.text = s.companyNuit;
    _companyEmail.text = s.companyEmail;
    _companyPhone.text = s.companyPhone;
    _companyAddress.text = s.companyAddress;
    _companyCity.text = s.companyCity ?? '';
    _companyProvince.text = s.companyProvince ?? '';
    _companyCountry.text = s.companyCountry;
    _companyLogo.text = s.companyLogo ?? '';
    _mpesaName.text = s.mpesaAccountName ?? '';
    _mpesaNumber.text = s.mpesaAccountNumber ?? '';
    _emolaName.text = s.emolaAccountName ?? '';
    _emolaNumber.text = s.emolaAccountNumber ?? '';
    _bankName.text = s.bankName ?? '';
    _bankAccountName.text = s.bankAccountName ?? '';
    _bankAccountNumber.text = s.bankAccountNumber ?? '';
    _bankNib.text = s.bankAccountNib ?? '';
    _bankSwift.text = s.bankAccountSwift ?? '';
    _bankInstructions.text = s.bankTransferInstructions ?? '';
    _invoiceFooter.text = s.invoiceFooter ?? '';
    _receiptFooter.text = s.receiptFooter ?? '';
    _defaultMessage.text = s.defaultMessage ?? '';
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Obrigatório' : null;

  String? _email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Obrigatório';
    if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
    return null;
  }

  String? _nuit(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Obrigatório';
    if (!RegExp(r'^\d{9}$').hasMatch(v)) return 'NUIT deve ter 9 dígitos';
    return null;
  }

  String? _phone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (v.isEmpty) return 'Obrigatório';
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(v)) return 'Contacto inválido';
    return null;
  }

  Future<void> _onPrimaryAction() async {
    if (!_editing) {
      setState(() => _editing = true);
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = PlatformCentralSettingsPayload(
      companyName: _companyName.text.trim(),
      companyNuit: _companyNuit.text.trim(),
      companyEmail: _companyEmail.text.trim(),
      companyPhone: _companyPhone.text.trim(),
      companyAddress: _companyAddress.text.trim(),
      companyCity: _nullable(_companyCity),
      companyProvince: _nullable(_companyProvince),
      companyCountry: _companyCountry.text.trim().isEmpty
          ? 'MZ'
          : _companyCountry.text.trim().toUpperCase(),
      companyLogo: _nullable(_companyLogo),
      mpesaAccountName: _nullable(_mpesaName),
      mpesaAccountNumber: _nullable(_mpesaNumber),
      emolaAccountName: _nullable(_emolaName),
      emolaAccountNumber: _nullable(_emolaNumber),
      bankName: _nullable(_bankName),
      bankAccountName: _nullable(_bankAccountName),
      bankAccountNumber: _nullable(_bankAccountNumber),
      bankAccountNib: _nullable(_bankNib),
      bankAccountSwift: _nullable(_bankSwift),
      bankTransferInstructions: _nullable(_bankInstructions),
      invoiceFooter: _nullable(_invoiceFooter),
      receiptFooter: _nullable(_receiptFooter),
      defaultMessage: _nullable(_defaultMessage),
    );

    try {
      await ref
          .read(platformBillingActionsProvider.notifier)
          .updateCentralSettings(payload);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _hydrated = false;
      });
      ref.invalidate(platformCentralSettingsProvider);
      PharmaFeedback.success(context, 'Configurações guardadas.');
    } catch (e) {
      if (!mounted) return;
      PharmaFeedback.error(
        context,
        e is ApiFailure ? e.message : e.toString(),
      );
    }
  }

  String? _nullable(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  void _cancel() {
    setState(() {
      _editing = false;
      _hydrated = false;
    });
    ref.invalidate(platformCentralSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(platformCentralSettingsProvider);
    final busy = ref.watch(platformBillingActionsProvider);
    final s = context.spacing;
    final maxFormWidth = context.widths.contentMax.clamp(0, 960).toDouble();
    final fieldsEnabled = _editing && !busy;

    return PageRefreshBinder(
      onRefresh: () async {
        setState(() {
          _editing = false;
          _hydrated = false;
        });
        ref.invalidate(platformCentralSettingsProvider);
      },
      child: EnterpriseModuleHub(
        title: 'Configurações da Central',
        subtitle:
            'Dados institucionais usados em faturas, recibos, PDFs e documentos oficiais.',
        tag: 'Plataforma',
        actions: [
          if (_editing)
            OutlinedButton(
              onPressed: busy ? null : _cancel,
              child: const Text('Cancelar'),
            ),
          FilledButton.icon(
            onPressed: busy ? null : _onPrimaryAction,
            icon: Icon(_editing ? Icons.save_outlined : Icons.edit_outlined),
            label: Text(
              busy
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
            title: 'Erro ao carregar configurações',
            message: e.toString(),
            onRetry: () {
              setState(() {
                _editing = false;
                _hydrated = false;
              });
              ref.invalidate(platformCentralSettingsProvider);
            },
          ),
          data: (settings) {
            _hydrate(settings);
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _SettingsSection(
                        title: 'Informações da Empresa',
                        child: EnterpriseFormGrid(
                          gap: s.md,
                          children: [
                            EnterpriseFormGridItem(
                              fullWidth: true,
                              child: EnterpriseTextFormField(
                                controller: _companyName,
                                labelText: 'Nome da Empresa *',
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                                validator: _required,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: 'Identificação',
                        child: EnterpriseFormGrid(
                          gap: s.md,
                          children: [
                            EnterpriseFormGridItem(
                              child: EnterpriseTextFormField(
                                controller: _companyNuit,
                                labelText: 'NUIT *',
                                keyboardType: TextInputType.number,
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(9),
                                ],
                                validator: _nuit,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              child: EnterpriseTextFormField(
                                controller: _companyEmail,
                                labelText: 'Email *',
                                keyboardType: TextInputType.emailAddress,
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                                validator: _email,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              child: EnterpriseTextFormField(
                                controller: _companyPhone,
                                labelText: 'Telefone *',
                                keyboardType: TextInputType.phone,
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                                validator: _phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: 'Localização',
                        child: EnterpriseFormGrid(
                          gap: s.md,
                          children: [
                            EnterpriseFormGridItem(
                              fullWidth: true,
                              child: EnterpriseTextFormField(
                                controller: _companyAddress,
                                labelText: 'Endereço *',
                                maxLines: 2,
                                minLines: 2,
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                                validator: _required,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              child: EnterpriseTextFormField(
                                controller: _companyCity,
                                labelText: 'Cidade',
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              child: EnterpriseTextFormField(
                                controller: _companyProvince,
                                labelText: 'Província',
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              child: EnterpriseTextFormField(
                                controller: _companyCountry,
                                labelText: 'País',
                                helperText: 'Código ISO (ex.: MZ)',
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: 'Documentos',
                        child: EnterpriseFormGrid(
                          gap: s.md,
                          children: [
                            EnterpriseFormGridItem(
                              fullWidth: true,
                              child: EnterpriseTextFormField(
                                controller: _companyLogo,
                                labelText: 'Logo (URL)',
                                helperText:
                                    'URL pública do logótipo institucional',
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              fullWidth: true,
                              child: EnterpriseTextFormField(
                                controller: _invoiceFooter,
                                labelText: 'Rodapé das Facturas',
                                maxLines: 3,
                                minLines: 2,
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              fullWidth: true,
                              child: EnterpriseTextFormField(
                                controller: _receiptFooter,
                                labelText: 'Rodapé dos Recibos',
                                maxLines: 3,
                                minLines: 2,
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            EnterpriseFormGridItem(
                              fullWidth: true,
                              child: EnterpriseTextFormField(
                                controller: _defaultMessage,
                                labelText: 'Mensagem padrão',
                                maxLines: 3,
                                minLines: 2,
                                readOnly: !fieldsEnabled,
                                enabled: fieldsEnabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: 'Recebimentos',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'M-Pesa',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            SizedBox(height: s.sm),
                            EnterpriseFormGrid(
                              gap: s.md,
                              children: [
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _mpesaName,
                                    labelText: 'Titular M-Pesa',
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _mpesaNumber,
                                    labelText: 'Número M-Pesa',
                                    keyboardType: TextInputType.phone,
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: s.lg),
                            Text(
                              'E-Mola',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            SizedBox(height: s.sm),
                            EnterpriseFormGrid(
                              gap: s.md,
                              children: [
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _emolaName,
                                    labelText: 'Titular E-Mola',
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _emolaNumber,
                                    labelText: 'Número E-Mola',
                                    keyboardType: TextInputType.phone,
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: s.lg),
                            Text(
                              'Transferência Bancária',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            SizedBox(height: s.sm),
                            EnterpriseFormGrid(
                              gap: s.md,
                              children: [
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _bankName,
                                    labelText: 'Banco',
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _bankAccountName,
                                    labelText: 'Nome da Conta',
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _bankAccountNumber,
                                    labelText: 'Número da Conta',
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _bankNib,
                                    labelText: 'NIB',
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                                EnterpriseFormGridItem(
                                  child: EnterpriseTextFormField(
                                    controller: _bankSwift,
                                    labelText: 'SWIFT',
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                                EnterpriseFormGridItem(
                                  fullWidth: true,
                                  child: EnterpriseTextFormField(
                                    controller: _bankInstructions,
                                    labelText:
                                        'Instruções para Transferência Bancária',
                                    maxLines: 3,
                                    minLines: 2,
                                    readOnly: !fieldsEnabled,
                                    enabled: fieldsEnabled,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: s.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_editing) ...[
                            OutlinedButton(
                              onPressed: busy ? null : _cancel,
                              child: const Text('Cancelar'),
                            ),
                            SizedBox(width: s.md),
                          ],
                          FilledButton(
                            onPressed: busy ? null : _onPrimaryAction,
                            child: Text(
                              busy
                                  ? 'A guardar…'
                                  : _editing
                                      ? 'Salvar'
                                      : 'Editar',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s.xl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.erpSectionTitle.copyWith(
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: s.sm),
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            elevation: 0,
            borderRadius: BorderRadius.circular(t.radiusMd),
            child: Padding(
              padding: EdgeInsets.all(s.md),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

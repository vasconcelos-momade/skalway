import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/enterprise_date_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';

import '../../../customers/data/repositories/customer_repository_impl.dart';
import '../../../customers/domain/entities/customer.dart';

class SaveProformaInvoiceDialogResult {
  const SaveProformaInvoiceDialogResult({
    required this.cliente,
    required this.validade,
    this.clienteId,
    this.nuit,
    this.contacto,
    this.descontoGeral,
    this.observacoes,
  });

  final String cliente;
  final String? clienteId;
  final DateTime validade;
  final String? nuit;
  final String? contacto;
  final double? descontoGeral;
  final String? observacoes;
}

class SaveProformaInvoiceDialogInitialData {
  const SaveProformaInvoiceDialogInitialData({
    required this.cliente,
    required this.validade,
    this.clienteId,
    this.nuit,
    this.contacto,
    this.descontoGeral,
    this.observacoes,
  });

  final String cliente;
  final String? clienteId;
  final DateTime validade;
  final String? nuit;
  final String? contacto;
  final double? descontoGeral;
  final String? observacoes;
}

class SaveProformaInvoiceDialog extends ConsumerStatefulWidget {
  const SaveProformaInvoiceDialog({super.key, this.initialData});

  final SaveProformaInvoiceDialogInitialData? initialData;

  @override
  ConsumerState<SaveProformaInvoiceDialog> createState() =>
      _SaveProformaInvoiceDialogState();
}

class _SaveProformaInvoiceDialogState
    extends ConsumerState<SaveProformaInvoiceDialog> {
  final _observacoesController = TextEditingController();
  final _clienteController = TextEditingController();
  final _nuitController = TextEditingController();
  final _contactoController = TextEditingController();
  final _descontoGeralController = TextEditingController();
  String? _clienteId;
  late DateTime _validade;
  bool _loadingCustomers = true;
  bool _manualClient = false;
  List<CustomerSummary> _customers = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    _validade = initial?.validade ?? DateTime.now().add(const Duration(days: 30));
    _clienteController.text = initial?.cliente ?? '';
    _nuitController.text = initial?.nuit ?? '';
    _contactoController.text = initial?.contacto ?? '';
    _descontoGeralController.text =
        (initial?.descontoGeral ?? 0).toStringAsFixed(2);
    _observacoesController.text = initial?.observacoes ?? '';
    _clienteId = initial?.clienteId;
    _manualClient = initial?.clienteId == null && (initial?.cliente.trim().isNotEmpty ?? false);
    Future.microtask(_loadCustomers);
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    _clienteController.dispose();
    _nuitController.dispose();
    _contactoController.dispose();
    _descontoGeralController.dispose();
    super.dispose();
  }

  void _applyCustomer(CustomerSummary? customer) {
    _clienteId = customer?.id;
    _clienteController.text = customer?.nome ?? '';
    _nuitController.text = customer?.nuit ?? '';
    _contactoController.text = customer?.telefone ?? '';
  }

  CustomerSummary? _findCustomerById(String? id) {
    if (id == null) {
      return null;
    }
    for (final customer in _customers) {
      if (customer.id == id) {
        return customer;
      }
    }
    return null;
  }

  Future<void> _loadCustomers() async {
    try {
      final response = await ref.read(customerRepositoryProvider).listCustomers(
            const CustomerQuery(page: 1, pageSize: 100),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = response.items;
        if (!_manualClient) {
          _applyCustomer(
            _findCustomerById(_clienteId) ??
                (response.items.isNotEmpty ? response.items.first : null),
          );
        }
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingCustomers = false;
        _error = e.toString();
      });
    }
  }

  void _submit() {
    final cliente = _clienteController.text.trim();
    if (cliente.isEmpty) {
      PharmaFeedback.error(context, 'Informe o cliente');
      return;
    }

    final descontoRaw = _descontoGeralController.text.trim();
    final descontoGeral = descontoRaw.isEmpty
        ? null
        : double.tryParse(descontoRaw.replaceAll(',', '.'));
    final descontoGeralSanitized = descontoGeral?.clamp(0, 1e12).toDouble();

    AdaptiveNavigator.complete(
      context,
      SaveProformaInvoiceDialogResult(
        cliente: cliente,
        clienteId: _manualClient ? null : _clienteId,
        validade: _validade,
        nuit: _nuitController.text.trim(),
        contacto: _contactoController.text.trim(),
        descontoGeral: descontoGeralSanitized,
        observacoes: _observacoesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return PharmaResponsiveDialog(
      title: const Text('Criar fatura proforma'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadingCustomers)
            const LinearProgressIndicator()
          else if (_error != null)
            Text(
              'Não foi possível carregar clientes.',
              style: Theme.of(context).textTheme.erpBody.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          else ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Preencher cliente manualmente'),
              value: _manualClient,
              onChanged: (value) {
                setState(() {
                  _manualClient = value;
                  if (value) {
                    _clienteId = null;
                  } else {
                    final selected = _customers.cast<CustomerSummary?>().firstWhere(
                          (c) => c?.id == _clienteId,
                          orElse: () =>
                              _customers.isNotEmpty ? _customers.first : null,
                        );
                    _applyCustomer(selected);
                  }
                });
              },
            ),
            if (!_manualClient)
              EnterpriseSelectFormField<String>(
                label: 'Cliente do cadastro *',
                initialValue: _clienteId,
                options: [
                  for (final customer in _customers)
                    EnterpriseSelectOption<String>(
                      value: customer.id,
                      label: customer.nome,
                    ),
                ],
                onChanged: (value) {
                  final customer = _findCustomerById(value);
                  setState(() => _applyCustomer(customer));
                },
              ),
          ],
          SizedBox(height: s.md),
          EnterpriseTextField(
            controller: _clienteController,
            labelText: 'Cliente *',
          ),
          SizedBox(height: s.md),
          EnterpriseTextField(
            controller: _nuitController,
            labelText: 'NUIT',
          ),
          SizedBox(height: s.md),
          EnterpriseTextField(
            controller: _contactoController,
            labelText: 'Contacto',
          ),
          SizedBox(height: s.md),
          EnterpriseDateField(
            labelText: 'Validade',
            value: _validade,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            onChanged: (picked) {
              if (picked != null) {
                setState(() => _validade = picked);
              }
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextField(
            controller: _descontoGeralController,
            labelText: 'Desconto Geral (MT)',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          SizedBox(height: s.md),
          EnterpriseTextField(
            controller: _observacoesController,
            labelText: 'Observações',
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => AdaptiveNavigator.cancel(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _loadingCustomers ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Criar'),
        ),
      ],
    );
  }
}

Future<SaveProformaInvoiceDialogResult?> showSaveProformaInvoiceDialog(
  BuildContext context,
{
  SaveProformaInvoiceDialogInitialData? initialData,
}) {
  return AdaptiveNavigator.open<SaveProformaInvoiceDialogResult>(
    context: context,
    builder: (_) => SaveProformaInvoiceDialog(initialData: initialData),
  );
}

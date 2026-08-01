import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/extensions.dart';
import '../../../../platform/printing/thermal/printer_connection.dart';
import '../../../../platform/printing/thermal/printer_discovery.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/printer.dart';

class PrinterFormResult {
  const PrinterFormResult({required this.payload});

  final Map<String, dynamic> payload;
}

Future<PrinterFormResult?> showPrinterFormDialog(
  BuildContext context, {
  PrinterDetalhe? printer,
}) {
  final title = Text(printer == null ? 'Nova impressora' : 'Editar impressora');

  return AdaptiveNavigator.openPanel<PrinterFormResult>(
    context: context,
    routeSettings: RouteSettings(
      name: printer == null ? '/impressoras/nova' : '/impressoras/${printer.id}',
    ),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: SafeArea(
            child: _PrinterFormDialog(printer: printer, embedded: true),
          ),
        );
      }
      return _PrinterFormDialog(
        printer: printer,
        embedded: true,
        showHeader: true,
        onClose: () => AdaptiveNavigator.cancel(detailContext),
      );
    },
  );
}

class _PrinterFormDialog extends ConsumerStatefulWidget {
  const _PrinterFormDialog({
    this.printer,
    this.embedded = false,
    this.showHeader = false,
    this.onClose,
  });

  final PrinterDetalhe? printer;
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_PrinterFormDialog> createState() => _PrinterFormDialogState();
}

class _PrinterFormDialogState extends ConsumerState<_PrinterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _ip;
  late final TextEditingController _port;
  late final TextEditingController _model;
  late final TextEditingController _manufacturer;
  late String _type;
  late String _connection;
  late bool _active;

  bool _discovering = false;
  List<PrinterConnection> _bluetoothDevices = const [];

  @override
  void initState() {
    super.initState();
    final printer = widget.printer;
    _name = TextEditingController(text: printer?.name ?? '');
    _ip = TextEditingController(text: printer?.ip ?? '');
    _port = TextEditingController(
      text: (printer?.port ?? 9100).toString(),
    );
    _model = TextEditingController(text: printer?.model ?? '');
    _manufacturer = TextEditingController(text: printer?.manufacturer ?? '');
    _type = printer?.type ?? 'ESC_POS';
    _connection = printer?.connection ?? 'NETWORK';
    _active = printer?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _ip.dispose();
    _port.dispose();
    _model.dispose();
    _manufacturer.dispose();
    super.dispose();
  }

  bool get _needsAddress =>
      _connection == 'NETWORK' || _connection == 'BLUETOOTH';

  Future<void> _discoverBluetooth() async {
    setState(() => _discovering = true);
    try {
      final devices =
          await ref.read(printerDiscoveryProvider).listBluetoothPrinters();
      if (!mounted) return;
      setState(() {
        _bluetoothDevices = devices;
        _discovering = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bluetoothDevices = const [];
        _discovering = false;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final port = int.tryParse(_port.text.trim());
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'type': _type,
      'connection': _connection,
      'active': _active,
      if (_needsAddress) 'ip': _ip.text.trim(),
      if (_connection == 'NETWORK') 'port': port ?? 9100,
      if (_model.text.trim().isNotEmpty) 'model': _model.text.trim(),
      if (_manufacturer.text.trim().isNotEmpty)
        'manufacturer': _manufacturer.text.trim(),
      if (widget.printer != null) 'version': widget.printer!.version,
    };

    AdaptiveNavigator.complete(context, PrinterFormResult(payload: payload));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.printer != null;
    final s = context.spacing;

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseSelectFormField<String>(
            label: 'Tipo de ligação *',
            initialValue: _connection,
            options: const [
              EnterpriseSelectOption(
                value: 'NETWORK',
                label: 'Rede (IP/WIFI)',
              ),
              EnterpriseSelectOption(
                value: 'USB',
                label: 'USB (Android/Desktop)',
              ),
              EnterpriseSelectOption(
                value: 'BLUETOOTH',
                label: 'Bluetooth',
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _connection = value);
              }
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _name,
            labelText: 'Nome *',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome é obrigatório';
              }
              return null;
            },
          ),
          if (_connection == 'NETWORK') ...[
            SizedBox(height: s.md),
            EnterpriseTextFormField(
              controller: _ip,
              labelText: 'Endereço IP *',
              hintText: 'ex: 192.168.1.100',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'IP é obrigatório para impressoras de rede';
                }
                return null;
              },
            ),
            SizedBox(height: s.md),
            EnterpriseTextFormField(
              controller: _port,
              labelText: 'Porta *',
              hintText: 'ex: 9100',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Porta é obrigatória';
                }
                return null;
              },
            ),
          ],
          if (_connection == 'BLUETOOTH') ...[
            SizedBox(height: s.sm),
            OutlinedButton.icon(
              onPressed: _discovering ? null : _discoverBluetooth,
              icon: _discovering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(
                _discovering
                    ? 'A procurar...'
                    : 'Procurar emparelhados (Android)',
              ),
            ),
            if (_bluetoothDevices.isNotEmpty) ...[
              SizedBox(height: s.sm),
              ..._bluetoothDevices.map(
                (device) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.label),
                  subtitle: Text(device.summary),
                  onTap: () {
                    setState(() {
                      _name.text =
                          _name.text.trim().isEmpty ? device.label : _name.text;
                      _ip.text = device.bluetoothAddress ?? '';
                    });
                  },
                ),
              ),
            ],
          ],
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _model,
            labelText: 'Modelo',
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _manufacturer,
            labelText: 'Fabricante',
          ),
          SizedBox(height: s.md),
          EnterpriseFormSwitch(
            label: 'Activa',
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
        ],
      ),
    );

    final actions = [
      EnterpriseOverlayActions.secondary(
        label: 'Cancelar',
        onPressed: () => AdaptiveNavigator.cancel(context),
      ),
      EnterpriseOverlayActions.primary(
        label: isEditing ? 'Guardar' : 'Criar',
        onPressed: _submit,
      ),
    ];

    if (widget.embedded) {
      if (widget.showHeader) {
        return EnterpriseFormSideSheet(
          title: Text(isEditing ? 'Editar impressora' : 'Nova impressora'),
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
      title: Text(isEditing ? 'Editar impressora' : 'Nova impressora'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(child: form),
      ),
      actions: actions,
    );
  }
}

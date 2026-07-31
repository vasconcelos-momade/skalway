import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../platform/printing/thermal/printer_connection.dart';
import '../../../../platform/printing/thermal/printer_discovery.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/layout/adaptive_side_sheet.dart';
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
  final width = AdaptiveNavigator.widthOf(context);
  final panelWidth = width >= AdaptiveSideSheetMetrics.desktopBreakpoint ? 520.0 : 480.0;

  return AdaptiveNavigator.openPanel<PrinterFormResult>(
    context: context,
    sideSheetWidth: panelWidth,
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome *'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome é obrigatório';
              }
              return null;
            },
          ),
          if (_connection == 'NETWORK') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _ip,
              decoration: const InputDecoration(
                labelText: 'Endereço IP *',
                hintText: 'ex: 192.168.1.100',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'IP é obrigatório para impressoras de rede';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _port,
              decoration: const InputDecoration(
                labelText: 'Porta *',
                hintText: 'ex: 9100',
              ),
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
            const SizedBox(height: 8),
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
              const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _model,
            decoration: const InputDecoration(labelText: 'Modelo'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _manufacturer,
            decoration: const InputDecoration(labelText: 'Fabricante'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activa'),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
        ],
      ),
    );

    final actions = [
      OutlinedButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: _submit,
        child: Text(isEditing ? 'Guardar' : 'Criar'),
      ),
    ];

    if (widget.embedded) {
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
                      isEditing ? 'Editar impressora' : 'Nova impressora',
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
              padding: const EdgeInsets.all(24),
              child: form,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
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

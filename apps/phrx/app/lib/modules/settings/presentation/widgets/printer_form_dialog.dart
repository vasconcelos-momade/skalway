import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../platform/printing/thermal/printer_connection.dart';
import '../../../../platform/printing/thermal/printer_discovery.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/printer.dart';

class PrinterFormResult {
  const PrinterFormResult({required this.payload});

  final Map<String, dynamic> payload;
}

Future<PrinterFormResult?> showPrinterFormDialog(
  BuildContext context, {
  PrinterDetalhe? printer,
}) {
  return AdaptiveNavigator.openEmbeddedForm<PrinterFormResult>(
    context: context,
    title: Text(printer == null ? 'Nova impressora' : 'Editar impressora'),
    routeSettings: RouteSettings(
      name: printer == null ? '/impressoras/nova' : '/impressoras/${printer.id}',
    ),
    formBuilder: (ctx, {required embedded}) =>
        _PrinterFormDialog(printer: printer, embedded: embedded),
  );
}

class _PrinterFormDialog extends ConsumerStatefulWidget {
  const _PrinterFormDialog({this.printer, this.embedded = false});

  final PrinterDetalhe? printer;
  final bool embedded;

  @override
  ConsumerState<_PrinterFormDialog> createState() => _PrinterFormDialogState();
}

class _PrinterFormDialogState extends ConsumerState<_PrinterFormDialog> {
  static const _types = ['ESC_POS', 'A4', 'LABEL'];
  static const _connections = ['NETWORK', 'BLUETOOTH', 'PDF', 'USB'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _ip;
  late final TextEditingController _port;
  late final TextEditingController _model;
  late final TextEditingController _manufacturer;
  late String _type;
  late String _connection;
  late bool _active;
  List<PrinterConnection> _bluetoothDevices = const [];
  bool _discovering = false;

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
    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _types.contains(_type) ? _type : _types.first,
            decoration: const InputDecoration(labelText: 'Tipo *'),
            items: [
              for (final type in _types)
                DropdownMenuItem(value: type, child: Text(type)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _type = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _connections.contains(_connection)
                ? _connection
                : _connections.first,
            decoration: const InputDecoration(labelText: 'Ligação *'),
            items: [
              for (final connection in _connections)
                DropdownMenuItem(value: connection, child: Text(connection)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _connection = value);
            },
          ),
          if (_needsAddress) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _ip,
              decoration: InputDecoration(
                labelText: _connection == 'NETWORK'
                    ? 'IP / Host *'
                    : 'Endereço Bluetooth *',
              ),
              validator: (value) {
                if (!_needsAddress) return null;
                if (value == null || value.trim().isEmpty) {
                  return _connection == 'NETWORK'
                      ? 'IP é obrigatório para impressoras de rede'
                      : 'Endereço Bluetooth é obrigatório';
                }
                return null;
              },
            ),
          ],
          if (_connection == 'NETWORK') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _port,
              decoration: const InputDecoration(labelText: 'Porta'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final port = int.tryParse(value.trim());
                if (port == null || port < 1 || port > 65535) {
                  return 'Porta inválida';
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

    if (widget.embedded) {
      return PharmaResponsiveDialog(
        title: Text(isEditing ? 'Editar impressora' : 'Nova impressora'),
        content: SingleChildScrollView(child: content),
        actions: [
          TextButton(
            onPressed: () => AdaptiveNavigator.complete(context, null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Guardar' : 'Criar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(isEditing ? 'Editar impressora' : 'Nova impressora'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(child: content),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Guardar' : 'Criar'),
        ),
      ],
    );
  }
}

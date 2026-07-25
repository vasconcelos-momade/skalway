import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> scanImplFromContext(BuildContext context) async {
  return Navigator.of(context, rootNavigator: true).push<String?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _BarcodeScannerPage(),
    ),
  );
}

Future<String?> scanImpl() async => null;

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final _controller = MobileScannerController();
  bool _returned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _return(String code) {
    if (_returned) return;
    _returned = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final raw = barcodes.first.rawValue?.trim();
          if (raw == null || raw.isEmpty) return;
          _return(raw);
        },
      ),
    );
  }
}


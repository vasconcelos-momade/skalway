import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';

/// Indicador de carregamento inline para botões (FilledButton, OutlinedButton, etc.).
class PharmaButtonLoader extends StatelessWidget {
  const PharmaButtonLoader({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DesignMetrics.buttonLoaderSize,
      height: DesignMetrics.buttonLoaderSize,
      child: CircularProgressIndicator(
        strokeWidth: DesignMetrics.buttonLoaderStrokeWidth,
        color: color,
      ),
    );
  }
}

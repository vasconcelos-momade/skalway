import 'package:flutter/material.dart';

import '../../../../../shared/widgets/feedback/module_data_states.dart';

class EstoqueLoading extends StatelessWidget {
  const EstoqueLoading({super.key, this.isDesktop = false});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return ModuleLoadingState(itemCount: isDesktop ? 10 : 8);
  }
}

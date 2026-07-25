import 'package:flutter/material.dart';

import '../../../../../shared/widgets/inputs/enterprise_search_field.dart';

class ProdutoSearchBar extends StatelessWidget {
  const ProdutoSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return EnterpriseSearchField(
      hintText: 'Pesquisar produto...',
      controller: controller,
      onChanged: onChanged,
    );
  }
}

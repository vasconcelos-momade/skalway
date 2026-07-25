import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../categories/presentation/providers/category_provider.dart';

/// Dropdown de categorias FNM (API) para filtros de catálogo.
class ProdutoCategoriaFilterDropdown extends ConsumerWidget {
  const ProdutoCategoriaFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.width,
    this.enabled = true,
    this.label = 'Categoria',
    this.emptyLabel = 'Todas',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final double? width;
  final bool enabled;
  final String label;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    if (!authReady || categoriesAsync.isLoading) {
      return EnterpriseSelectField<String>(
        label: label,
        width: width,
        emptyLabel: emptyLabel,
        value: value,
        options: const [],
        onChanged: null,
        enabled: false,
      );
    }

    return categoriesAsync.when(
      loading: () => EnterpriseSelectField<String>(
        label: label,
        width: width,
        emptyLabel: emptyLabel,
        value: value,
        options: const [],
        onChanged: null,
        enabled: false,
      ),
      error: (_, _) => EnterpriseSelectField<String>(
        label: label,
        width: width,
        emptyLabel: emptyLabel,
        value: value,
        options: const [],
        onChanged: enabled ? onChanged : null,
        enabled: enabled,
      ),
      data: (categories) {
        final resolved = value != null && categories.any((c) => c.id == value)
            ? value
            : null;
        return EnterpriseSelectField<String>(
          label: label,
          width: width,
          emptyLabel: emptyLabel,
          value: resolved,
          enabled: enabled,
          options: [
            for (final cat in categories)
              EnterpriseSelectOption<String>(
                value: cat.id,
                label: cat.nome,
              ),
          ],
          onChanged: enabled ? onChanged : null,
        );
      },
    );
  }
}

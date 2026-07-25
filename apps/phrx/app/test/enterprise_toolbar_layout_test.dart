import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phrx/core/theme/app_theme.dart';
import 'package:phrx/shared/widgets/inputs/enterprise_select_field.dart';
import 'package:phrx/shared/widgets/layout/enterprise_mobile_toolbar.dart';

void main() {
  testWidgets('desktop toolbar search+select layout does not assert', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final search = TextEditingController();
    addTearDown(search.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightEnterprise(),
        home: Scaffold(
          body: Column(
            children: [
              EnterpriseDesktopListToolbar(
                searchController: search,
                searchHint: 'Pesquisar produto...',
                isLoading: false,
                onSearchSubmitted: (_) {},
                hasFilters: true,
                onClearFilters: () {},
                filterWidgets: const [
                  SizedBox(
                    width: 168,
                    child: EnterpriseSelectField<bool>(
                      label: 'Status',
                      emptyLabel: 'Todos',
                      value: null,
                      options: [
                        EnterpriseSelectOption(value: true, label: 'Activos'),
                        EnterpriseSelectOption(value: false, label: 'Inactivos'),
                      ],
                      onChanged: _noopBool,
                    ),
                  ),
                ],
                trailingActions: [
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Novo'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 30,
                  itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);
  });
}

void _noopBool(bool? _) {}

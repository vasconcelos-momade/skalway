import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phrx/modules/pharmacy/expiry/presentation/pages/expiry_page.dart';
import 'package:phrx/modules/pharmacy/expiry/presentation/providers/expiry_provider.dart';

void main() {
  testWidgets('ExpiryPage renders title and table content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expiryViewProvider.overrideWith(_MockExpiryController.new),
        ],
        child: const MaterialApp(home: Scaffold(body: ExpiryPage())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.takeException();

    expect(find.text('CANDIGEN CREME'), findsOneWidget);
    expect(find.text('Expirados'), findsOneWidget);
  });
}

class _MockExpiryController extends ExpiryViewController {
  @override
  Future<ExpiryViewState> build() async {
    return ExpiryViewState(
      dashboard: const {
        'lotesExpirados': 0,
        'expiramEm30Dias': 1,
        'expiramEm60Dias': 2,
        'valorFinanceiroEmRisco': 100,
      },
      items: const [
        {
          'id': '1',
          'produtoNome': 'CANDIGEN CREME',
          'numeroLote': 'TEST-1',
          'dataValidade': '2028-12-31T00:00:00.000Z',
          'diasRestantes': 900,
          'quantidadeDisponivel': 50,
          'valorEmStock': 100,
          'estado': 'OK',
        },
      ],
      lastUpdated: DateTime.now(),
      totalCount: 1,
    );
  }
}

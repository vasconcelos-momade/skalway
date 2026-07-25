import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_providers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    prefs = await initTestSharedPreferences();
  });

  testWidgets('App arranca no login', (WidgetTester tester) async {
    await tester.pumpWidget(testLoginApp(prefs));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pharma ERP'), findsWidgets);
    expect(find.text('Entrar'), findsOneWidget);
  });
}

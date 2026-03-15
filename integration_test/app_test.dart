import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:project_1/main.dart' as app;

/// Integration test for graduate requirement: end-to-end app flow.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and home screen is visible', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Mystery Puzzle Companion'), findsOneWidget);
  });

  testWidgets('Navigate to Missions tab and see screen', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.tap(find.text('Missions'));
    await tester.pumpAndSettle();
    expect(find.text('Missions'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:trust_route/main.dart' as app;

void main() {
  testWidgets('TrustRoute app starts on login screen', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('TrustRoute'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

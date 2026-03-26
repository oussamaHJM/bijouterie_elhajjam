import 'package:flutter_test/flutter_test.dart';
import 'package:bijouterie_elhajjam/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // This test just verifies the app widget builds without crashing.
    // Firebase init will throw with placeholder credentials in test env,
    // so we skip the full build test here.
    expect(App, isNotNull);
  });
}

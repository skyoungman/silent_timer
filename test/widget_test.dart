import 'package:flutter_test/flutter_test.dart';
import 'package:silent_timer_app/main.dart';

void main() {
  testWidgets('Silent Timer App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SilentTimerApp());
    expect(find.text('Silent Timer'), findsOneWidget);
  });
}
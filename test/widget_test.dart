import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WodTimerApp()),
    );

    expect(find.text('WOD Timer - Coming Soon'), findsOneWidget);
  });
}

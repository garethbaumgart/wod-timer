import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/main.dart';

void main() {
  testWidgets('App renders correctly with home page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WodTimerApp()),
    );
    await tester.pumpAndSettle();

    // Check that the home page renders with timer type selection
    expect(find.text('WOD Timer'), findsOneWidget);
    expect(find.text('Select Timer Type'), findsOneWidget);
    expect(find.text('AMRAP'), findsOneWidget);
    expect(find.text('FOR TIME'), findsOneWidget);
    expect(find.text('EMOM'), findsOneWidget);
    expect(find.text('TABATA'), findsOneWidget);
  });
}

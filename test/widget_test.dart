import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/main.dart';

void main() {
  testWidgets('App renders correctly with home page', (
    WidgetTester tester,
  ) async {
    // Home reads each mode's remembered setup, so the app needs the loaded
    // SharedPreferences that main() provides.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const WodTimerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Check that the Signal design home page renders with all four
    // timer type strip items
    expect(find.text('AMRAP'), findsOneWidget);
    expect(find.text('FOR TIME'), findsOneWidget);
    expect(find.text('EMOM'), findsOneWidget);
    expect(find.text('TABATA'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/wordmark.dart';

void main() {
  Future<void> pump(WidgetTester tester, {double wodSize = 64}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Wordmark(wodSize: wodSize),
          ),
        ),
      ),
    );
  }

  testWidgets('stacks a white WHARF over a green WOD with a pink stop', (
    tester,
  ) async {
    await pump(tester);

    final wharf = tester.widget<Text>(find.text('WHARF'));
    expect(wharf.style!.color, Colors.white);
    expect(wharf.style!.fontWeight, FontWeight.w800);
    expect(wharf.style!.fontSize, closeTo(64 * 0.278, 0.01));
    expect(wharf.style!.letterSpacing, closeTo(64 * 0.12, 0.01));

    final wod = tester.widget<Text>(find.byType(Text).last);
    final spans = (wod.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans.map((s) => s.text), ['WOD', '.']);
    expect(spans[0].style!.color, AppColors.primary);
    expect(spans[0].style!.fontSize, 64);
    expect(spans[0].style!.letterSpacing, closeTo(-64 * 0.028, 0.01));
    expect(spans[0].style!.height, 0.9);
    expect(spans[1].style!.color, AppColors.emomAccent);

    // WHARF sits above WOD.
    expect(
      tester.getRect(find.text('WHARF')).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(Text).last).top + 1),
    );
    expect(find.text('WHARF WOD'), findsNothing);
  });

  testWidgets('glow is soft on colours and faint on white', (tester) async {
    await pump(tester);

    final wharf = tester.widget<Text>(find.text('WHARF')).style!;
    expect(wharf.shadows, hasLength(1));
    expect(wharf.shadows!.single.color.a, closeTo(0.18, 0.01));

    final wod = tester.widget<Text>(find.byType(Text).last);
    final green = (wod.textSpan! as TextSpan).children!.first.style!;
    expect(green.shadows, hasLength(2));
    expect(green.shadows!.first.color.a, closeTo(0.5, 0.01));
  });

  testWidgets('reads as one header to a screen reader', (tester) async {
    await pump(tester);
    expect(find.bySemanticsLabel('Wharf WOD'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Wharf WOD')),
      containsSemantics(isHeader: true),
    );
  });
}

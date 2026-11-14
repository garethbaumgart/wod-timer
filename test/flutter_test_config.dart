import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/screen_harness.dart';

/// Loads the bundled Outfit weights once per widget-test file, before any
/// test runs.
///
/// Flutter 3.50 delivers a loaded font's `fontsChange` system message only
/// once real time passes, so a font first drawn inside a test schedules its
/// relayout frame after the test has torn down, and the test fails with "An
/// animation is still running even after the widget tree was disposed".
/// Loading the fonts here, while no widget is mounted, lets those messages
/// land harmlessly and gives every test the shipped glyph metrics from its
/// first frame.
///
/// Only files that declare widget tests have a binding by the time this
/// runs (`testWidgets` creates it); plain unit-test files are left alone.
/// The theme tests start cold on purpose: see
/// `core/presentation/theme/flutter_test_config.dart`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    if (BindingBase.debugBindingType() == null) return;
    await loadOutfit();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await testMain();
}

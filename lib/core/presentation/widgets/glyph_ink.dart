import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Where painted glyphs end inside a laid-out line of Outfit text.
///
/// Layout rule 2 (1.3.1) centres every timeline between the visible bottom
/// of the content above it and the bottom buttons, measured from glyph
/// bottoms rather than box edges. A text box in Flutter ends at the font's
/// descender line (0.26em below the baseline in Outfit), well under where
/// capitals and digits stop, and a few glyphs (the slash, round digits)
/// overshoot the baseline. This measures the real ink bottom: the baseline
/// from TextPainter plus the glyph's overshoot from the font's own
/// outlines.
abstract class GlyphInk {
  /// Thousandths of an em that Outfit paints below the baseline, per
  /// weight, for every glyph that does so (from the bundled fonts' glyf
  /// tables). Glyphs not listed stop on the baseline.
  static const Map<int, Map<String, int>> _belowBaseline = {
    600: {
      '0': 10,
      '3': 10,
      '5': 10,
      '6': 10,
      '8': 10,
      ':': 10,
      '/': 47,
      '.': 10,
      'C': 10,
      'G': 10,
      'J': 10,
      'O': 11,
      'Q': 52,
      'S': 10,
      'U': 10,
      'a': 10,
      'b': 10,
      'c': 10,
      'd': 10,
      'e': 10,
      'g': 214,
      'j': 214,
      'o': 10,
      'p': 202,
      'q': 202,
      's': 11,
      'u': 10,
      'y': 202,
    },
    700: {
      '0': 11,
      '3': 11,
      '5': 11,
      '6': 11,
      '8': 11,
      ':': 11,
      '/': 55,
      '.': 11,
      'C': 11,
      'G': 11,
      'J': 11,
      'O': 12,
      'Q': 56,
      'S': 11,
      'U': 11,
      'a': 10,
      'b': 10,
      'c': 11,
      'd': 10,
      'e': 11,
      'g': 218,
      'j': 218,
      'o': 11,
      'p': 205,
      'q': 205,
      's': 12,
      'u': 11,
      'y': 205,
    },
    800: {
      '0': 11,
      '3': 11,
      '5': 11,
      '6': 11,
      '8': 11,
      ':': 11,
      '/': 62,
      '.': 11,
      'C': 11,
      'G': 11,
      'J': 11,
      'O': 13,
      'Q': 61,
      'S': 11,
      'U': 11,
      'a': 10,
      'b': 10,
      'c': 11,
      'd': 10,
      'e': 11,
      'g': 222,
      'j': 222,
      'o': 11,
      'p': 207,
      'q': 207,
      's': 14,
      'u': 11,
      'y': 207,
    },
    900: {
      '0': 12,
      '3': 12,
      '5': 12,
      '6': 12,
      '8': 12,
      ':': 12,
      '/': 70,
      '.': 12,
      'C': 12,
      'G': 12,
      'J': 12,
      'O': 14,
      'Q': 65,
      'S': 12,
      'U': 12,
      'a': 10,
      'b': 10,
      'c': 12,
      'd': 10,
      'e': 12,
      'g': 226,
      'j': 226,
      'o': 12,
      'p': 210,
      'q': 210,
      's': 15,
      'u': 12,
      'y': 210,
    },
  };

  /// The style a Text widget under [context] really renders [style] with:
  /// Material's DefaultTextStyle contributes what [style] leaves null (its
  /// even leading distribution moves the baseline), so measurements must
  /// start from the same merged style.
  static TextStyle resolve(BuildContext context, TextStyle style) =>
      DefaultTextStyle.of(context).style.merge(style);

  /// How far below the baseline [text] paints, in em.
  static double belowBaselineEm(String text, FontWeight weight) {
    final key = (weight.value.clamp(600, 900) / 100).round() * 100;
    final table = _belowBaseline[key]!;
    var deepest = 0;
    for (final rune in text.runes) {
      final glyph = String.fromCharCode(rune);
      deepest = math.max(deepest, table[glyph] ?? 0);
    }
    return deepest / 1000;
  }

  /// Outfit's cap height (digits are lining figures at the same height),
  /// in em, per weight.
  static double capHeightEm(FontWeight weight) => switch (weight.value) {
    >= 900 => 0.712,
    >= 800 => 0.709,
    >= 700 => 0.706,
    _ => 0.703,
  };

  /// Distance from the top of a laid-out line of [text] to its alphabetic
  /// baseline.
  static double baseline(
    String text,
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => _painter(
    text,
    style,
    textScaler,
  ).computeDistanceToActualBaseline(TextBaseline.alphabetic);

  /// The laid-out width of one line of [text].
  static double boxWidth(
    String text,
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => _painter(text, style, textScaler).width;

  /// The laid-out height of one line of [text] (what a Text widget takes).
  static double boxHeight(
    String text,
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => _painter(text, style, textScaler).height;

  /// Distance from the top of a laid-out line of [text] to the bottom of
  /// its painted glyphs.
  static double glyphBottom(
    String text,
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final painter = _painter(text, style, textScaler);
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final fontSize = textScaler.scale(style.fontSize ?? 14);
    final weight = style.fontWeight ?? FontWeight.w400;
    return baseline + belowBaselineEm(text, weight) * fontSize;
  }

  /// Distance from the bottom of a laid-out line of [text] up to the
  /// bottom of its painted glyphs: the part of the box that is empty.
  /// Negative when the glyphs overshoot a trimmed line box.
  static double bottomInset(
    String text,
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final painter = _painter(text, style, textScaler);
    return painter.height - glyphBottom(text, style, textScaler: textScaler);
  }

  static TextPainter _painter(
    String text,
    TextStyle style,
    TextScaler textScaler,
  ) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/utils/string_utils.dart';

void main() {
  group('StringUtils.toTitleCase', () {
    test('handles empty and null inputs', () {
      expect(StringUtils.toTitleCase(null), '');
      expect(StringUtils.toTitleCase(''), '');
      expect(StringUtils.toTitleCase('    '), '');
    });

    test('converts lowercase text to title case', () {
      expect(StringUtils.toTitleCase('aha tomato'), 'Aha Tomato');
      expect('aha tomato'.toTitleCase(), 'Aha Tomato');
    });

    test('converts uppercase and mixed case text to title case', () {
      expect(StringUtils.toTitleCase('AHA TOMATO'), 'Aha Tomato');
      expect(StringUtils.toTitleCase('aHa ToMaTo'), 'Aha Tomato');
    });

    test('normalizes irregular whitespace', () {
      expect(StringUtils.toTitleCase('   aha    tomato   '), 'Aha Tomato');
      expect(StringUtils.toTitleCase('bright   sunlight'), 'Bright Sunlight');
    });

    test('handles single character and hyphenated words', () {
      expect(StringUtils.toTitleCase('a'), 'A');
      expect(StringUtils.toTitleCase('sleep-related'), 'Sleep-Related');
      expect(StringUtils.toTitleCase('SUGAR-FREE CANDY'), 'Sugar-Free Candy');
    });

    test('handles numbers and special symbols', () {
      expect(StringUtils.toTitleCase('day 2 screen time'), 'Day 2 Screen Time');
      expect(StringUtils.toTitleCase('100% coffee'), '100% Coffee');
    });
  });
}

/// Utility functions and extensions for string transformations across the app.
class StringUtils {
  StringUtils._();

  /// Converts any string into Title Case (capitalizing the first letter of each
  /// word and lowercasing the rest).
  ///
  /// Examples:
  /// - `"aha tomato"` -> `"Aha Tomato"`
  /// - `"AHA TOMATO"` -> `"Aha Tomato"`
  /// - `"aHA tOMaTO"` -> `"Aha Tomato"`
  /// - `"  bright   sunlight  "` -> `"Bright Sunlight"`
  /// - `"sugar-free candy"` -> `"Sugar-Free Candy"`
  static String toTitleCase(String? input) {
    if (input == null) return '';
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    // Split words by one or more whitespace characters
    final words = trimmed.split(RegExp(r'\s+'));

    final formattedWords = words.map((word) {
      if (word.isEmpty) return '';

      // If the word has hyphens (e.g. "sleep-related"), capitalize each hyphenated segment
      if (word.contains('-')) {
        return word.split('-').map(_capitalizeSegment).join('-');
      }

      return _capitalizeSegment(word);
    });

    return formattedWords.join(' ');
  }

  static String _capitalizeSegment(String segment) {
    if (segment.isEmpty) return '';
    if (segment.length == 1) return segment.toUpperCase();
    return segment[0].toUpperCase() + segment.substring(1).toLowerCase();
  }
}

/// Extension on [String] for convenient title casing.
extension StringCasingExtension on String {
  /// Converts this string to Title Case.
  String toTitleCase() => StringUtils.toTitleCase(this);
}

import 'package:shared_preferences/shared_preferences.dart';

class CausePrefs {
  static const _causesKey = 'cause_options';

  static const List<String> defaultCauses = [
    "Stress",
    "Smoke",
    "Food contents",
    "AC",
    "Dehydration",
    "Odour",
    "Sleep related",
    "Screen Time",
    "Skipped Meal",
    "Weather",
    "Other",
  ];

  static Future<List<String>> loadCauses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_causesKey) ?? const [];
    final cleaned = saved
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return List<String>.from(defaultCauses);
    return cleaned;
  }

  static Future<void> saveCauses(List<String> causes) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = causes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await prefs.setStringList(_causesKey, cleaned);
  }
}

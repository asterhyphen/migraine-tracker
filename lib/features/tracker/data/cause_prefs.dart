import 'package:shared_preferences/shared_preferences.dart';

import '../models/cause_option.dart';

class CausePrefs {
  static const _causesKey = 'cause_options';

  static Future<List<String>> loadCauses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_causesKey) ?? const [];
    final cleaned = saved
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return List<String>.from(defaultCauseOptions);
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

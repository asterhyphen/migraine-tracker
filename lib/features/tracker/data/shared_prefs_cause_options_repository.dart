import 'package:shared_preferences/shared_preferences.dart';

import '../models/cause_option.dart';
import 'cause_options_repository.dart';

class SharedPrefsCauseOptionsRepository implements CauseOptionsRepository {
  const SharedPrefsCauseOptionsRepository();

  static const _causesKey = 'cause_options';

  @override
  Future<List<String>> loadCauses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_causesKey) ?? const [];
    final cleaned = saved
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return List<String>.from(defaultCauseOptions);
    return cleaned;
  }

  @override
  Future<void> saveCauses(List<String> causes) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = causes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await prefs.setStringList(_causesKey, cleaned);
  }
}

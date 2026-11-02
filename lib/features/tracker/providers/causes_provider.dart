import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_prefs_cause_options_repository.dart';
import '../models/cause_option.dart';
import '../data/cause_options_repository.dart';

final causeOptionsRepositoryProvider = Provider<CauseOptionsRepository>(
  (ref) => const SharedPrefsCauseOptionsRepository(),
);

final causeOptionsProvider =
    AsyncNotifierProvider<CauseOptionsController, List<String>>(
      CauseOptionsController.new,
    );

class CauseOptionsController extends AsyncNotifier<List<String>> {
  CauseOptionsRepository get _repository =>
      ref.read(causeOptionsRepositoryProvider);

  @override
  Future<List<String>> build() {
    return _repository.loadCauses();
  }

  Future<List<String>> reload() async {
    state = const AsyncValue.loading();
    final next = await _repository.loadCauses();
    state = AsyncValue.data(next);
    return next;
  }

  Future<void> save(List<String> causes) async {
    final cleaned = causes
        .map((cause) => cause.trim())
        .where((cause) => cause.isNotEmpty)
        .toList();
    await _repository.saveCauses(cleaned);
    state = AsyncValue.data(cleaned.isEmpty ? defaultCauseOptions : cleaned);
  }

  Future<bool> addCause(String cause) async {
    final trimmed = cause.trim();
    if (trimmed.isEmpty) return false;
    final current = state.value ?? await _repository.loadCauses();
    if (current.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      return false;
    }
    final updated = List<String>.from(current);
    final otherIndex = updated.indexWhere((c) => c.toLowerCase() == 'other');
    if (otherIndex != -1) {
      updated.insert(otherIndex, trimmed);
    } else {
      updated.add(trimmed);
    }
    await save(updated);
    return true;
  }

  Future<void> removeCause(String cause) async {
    final current = state.value ?? await _repository.loadCauses();
    final updated = current.where((c) => c != cause).toList();
    await save(updated);
  }

  Future<void> reorderCauses(int oldIndex, int newIndex) async {
    final current = state.value ?? await _repository.loadCauses();
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex >= current.length) return;
    final updated = List<String>.from(current);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    await save(updated);
  }
}

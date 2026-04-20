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
}

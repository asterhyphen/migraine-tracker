import 'cause_options_repository.dart';
import 'cause_prefs.dart';

class SharedPrefsCauseOptionsRepository implements CauseOptionsRepository {
  const SharedPrefsCauseOptionsRepository();

  @override
  Future<List<String>> loadCauses() {
    return CausePrefs.loadCauses();
  }

  @override
  Future<void> saveCauses(List<String> causes) {
    return CausePrefs.saveCauses(causes);
  }
}

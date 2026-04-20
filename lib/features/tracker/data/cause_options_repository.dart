abstract class CauseOptionsRepository {
  Future<List<String>> loadCauses();
  Future<void> saveCauses(List<String> causes);
}

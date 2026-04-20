import '../models/migraine_entry.dart';

abstract class MigraineRepository {
  Future<void> deleteEntry(int id);
  Future<List<MigraineEntry>> getMigraineEntriesOnly();
  Future<MigraineEntry?> getEntryForDate(DateTime date);
  Future<void> insertEntries(List<MigraineEntry> entries);
  Future<void> saveEntry(MigraineEntry entry);
}

import '../models/migraine_entry.dart';

abstract class MigraineRepository {
  Future<void> deleteEntry(int id);
  Future<List<MigraineEntry>> getMigraineEntriesOnly();
  Future<List<MigraineEntry>> getAllEntries();
  Future<MigraineEntry?> getEntryForDate(DateTime date);
  Future<MigraineEntry?> getAnyEntryForDate(DateTime date);
  Future<void> insertEntries(List<MigraineEntry> entries);
  Future<void> saveEntry(MigraineEntry entry);
  Future<void> updateOutcome(int id, MigraineOutcome outcome);
}

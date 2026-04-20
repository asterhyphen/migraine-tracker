import '../models/migraine_entry.dart';
import 'migraine_repository.dart';
import 'migraine_db.dart';

class SqfliteMigraineRepository implements MigraineRepository {
  const SqfliteMigraineRepository(this._db);

  final MigraineDb _db;

  @override
  Future<void> deleteEntry(int id) async {
    await _db.deleteEntry(id);
  }

  @override
  Future<List<MigraineEntry>> getMigraineEntriesOnly() {
    return _db.getMigraineEntriesOnly();
  }

  @override
  Future<MigraineEntry?> getEntryForDate(DateTime date) {
    return _db.getEntryForDate(date);
  }

  @override
  Future<void> insertEntries(List<MigraineEntry> entries) {
    return _db.insertEntries(entries);
  }

  @override
  Future<void> saveEntry(MigraineEntry entry) async {
    await _db.updateEntry(entry);
  }
}

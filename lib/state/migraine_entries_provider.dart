import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';

final migraineDbProvider = Provider<MigraineDb>((ref) => MigraineDb.instance);

final migraineEntriesProvider =
    AsyncNotifierProvider<MigraineEntriesController, List<MigraineEntry>>(
      MigraineEntriesController.new,
    );

class MigraineEntriesController extends AsyncNotifier<List<MigraineEntry>> {
  MigraineDb get _db => ref.read(migraineDbProvider);

  @override
  Future<List<MigraineEntry>> build() {
    return _db.getMigraineEntriesOnly();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_db.getMigraineEntriesOnly);
  }

  Future<MigraineEntry?> entryForDate(DateTime date) {
    return _db.getEntryForDate(date);
  }

  Future<void> saveEntry(MigraineEntry entry) async {
    await _db.updateEntry(entry);
    await reload();
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteEntry(id);
    await reload();
  }

  Future<void> insertEntries(List<MigraineEntry> entries) async {
    await _db.insertEntries(entries);
    await reload();
  }
}

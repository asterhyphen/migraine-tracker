import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/migraine_db.dart';
import '../data/migraine_repository.dart';
import '../data/sqflite_migraine_repository.dart';
import '../models/migraine_entry.dart';

final migraineDbProvider = Provider<MigraineDb>((ref) => MigraineDb.instance);

final migraineRepositoryProvider = Provider<MigraineRepository>(
  (ref) => SqfliteMigraineRepository(ref.watch(migraineDbProvider)),
);

final migraineEntriesProvider =
    AsyncNotifierProvider<MigraineEntriesController, List<MigraineEntry>>(
      MigraineEntriesController.new,
    );

class MigraineEntriesController extends AsyncNotifier<List<MigraineEntry>> {
  MigraineRepository get _repository => ref.read(migraineRepositoryProvider);

  @override
  Future<List<MigraineEntry>> build() {
    return _repository.getMigraineEntriesOnly();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getMigraineEntriesOnly);
  }

  Future<MigraineEntry?> entryForDate(DateTime date) {
    return _repository.getEntryForDate(date);
  }

  Future<void> saveEntry(MigraineEntry entry) async {
    await _repository.saveEntry(entry);
    await reload();
  }

  Future<void> deleteEntry(int id) async {
    await _repository.deleteEntry(id);
    await reload();
  }

  Future<void> insertEntries(List<MigraineEntry> entries) async {
    await _repository.insertEntries(entries);
    await reload();
  }
}

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migraine_entry.dart';

class MigraineDb {
  MigraineDb._();

  static final MigraineDb instance = MigraineDb._();

  static const _dbName = 'migraine_tracker.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await _openDb();
    _db = db;
    return db;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE migraine_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date INTEGER NOT NULL,
            had_migraine INTEGER NOT NULL,
            intensity INTEGER NOT NULL,
            painkillers INTEGER NOT NULL,
            notes TEXT NOT NULL,
            causes TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Legacy schema had `medication` as NOT NULL. Rebuild to the
          // current schema so inserts from current app versions succeed.
          await db.transaction((txn) async {
            await txn.execute('''
              CREATE TABLE migraine_entries_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date INTEGER NOT NULL,
                had_migraine INTEGER NOT NULL,
                intensity INTEGER NOT NULL,
                painkillers INTEGER NOT NULL,
                notes TEXT NOT NULL,
                causes TEXT NOT NULL
              )
            ''');
            await txn.execute('''
              INSERT INTO migraine_entries_new
              (id, date, had_migraine, intensity, painkillers, notes, causes)
              SELECT id, date, had_migraine, intensity, painkillers, notes, causes
              FROM migraine_entries
            ''');
            await txn.execute('DROP TABLE migraine_entries');
            await txn.execute(
              'ALTER TABLE migraine_entries_new RENAME TO migraine_entries',
            );
          });
        }
      },
    );
  }

  Future<int> insertEntry(MigraineEntry entry) async {
    final db = await database;
    return db.insert('migraine_entries', entry.toMap());
  }

  Future<int> updateEntry(MigraineEntry entry) async {
    if (entry.id == null) {
      return insertEntry(entry);
    }
    final db = await database;
    return db.update(
      'migraine_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('migraine_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MigraineEntry>> getAllEntries() async {
    final db = await database;
    final rows = await db.query('migraine_entries', orderBy: 'date DESC');
    return rows.map(MigraineEntry.fromMap).toList();
  }

  Future<List<MigraineEntry>> getMigraineEntriesOnly() async {
    final db = await database;
    final rows = await db.query(
      'migraine_entries',
      where: 'had_migraine = ?',
      whereArgs: [1],
      orderBy: 'date DESC',
    );
    return rows.map(MigraineEntry.fromMap).toList();
  }

  Future<void> insertEntries(List<MigraineEntry> entries) async {
    if (entries.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final entry in entries) {
      batch.insert('migraine_entries', entry.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<MigraineEntry>> getEntriesForMonth(DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final rows = await db.query(
      'migraine_entries',
      where: 'date >= ? AND date < ? AND had_migraine = ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, 1],
      orderBy: 'date DESC',
    );
    return rows.map(MigraineEntry.fromMap).toList();
  }

  Future<MigraineEntry?> getEntryForDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'migraine_entries',
      where: 'date >= ? AND date < ? AND had_migraine = ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, 1],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MigraineEntry.fromMap(rows.first);
  }
}

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migraine_entry.dart';

class MigraineDb {
  MigraineDb._();

  static final MigraineDb instance = MigraineDb._();

  static const _dbName = 'migraine_tracker.db';
  static const _dbVersion = 1;

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
            medication TEXT NOT NULL,
            notes TEXT NOT NULL,
            causes TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertEntry(MigraineEntry entry) async {
    final db = await database;
    return db.insert('migraine_entries', entry.toMap());
  }

  Future<List<MigraineEntry>> getAllEntries() async {
    final db = await database;
    final rows = await db.query(
      'migraine_entries',
      orderBy: 'date DESC',
    );
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
}

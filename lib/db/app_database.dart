import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/question.dart';

/// Local SQLite store: practice history with per-question details.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'xingce_local.db';
  static const _dbVersion = 2;

  /// Last write error, surfaced in the history screen for diagnosis.
  static String? lastError;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    try {
      return await openDatabase(path,
          version: _dbVersion,
          onCreate: _createSchema,
          onUpgrade: _upgradeSchema);
    } catch (e) {
      // Corrupted or partially-created db: drop and recreate once.
      // ignore: avoid_print
      print('AppDatabase open failed, recreating: $e');
      try {
        await deleteDatabase(path);
      } catch (_) {}
      return openDatabase(path,
          version: _dbVersion,
          onCreate: _createSchema,
          onUpgrade: _upgradeSchema);
    }
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE practice_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module TEXT NOT NULL,
        module_name TEXT NOT NULL,
        type_id TEXT NOT NULL,
        type_name TEXT NOT NULL,
        total INTEGER NOT NULL,
        correct INTEGER NOT NULL,
        seconds INTEGER NOT NULL,
        done_at TEXT NOT NULL,
        details TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_records_done ON practice_records(done_at)');
  }

  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE practice_records ADD COLUMN details TEXT');
    }
  }

  // ---------- practice records ----------

  Future<void> addRecord(PracticeRecord r) async {
    try {
      final db = await database;
      await db.insert('practice_records', r.toJson());
    } catch (e) {
      lastError = '$e';
      // ignore: avoid_print
      print('addRecord failed: $e');
    }
  }

  Future<List<PracticeRecord>> getRecords({int limit = 500}) async {
    try {
      final db = await database;
      final rows = await db.query('practice_records',
          orderBy: 'done_at DESC', limit: limit);
      return rows.map((r) => PracticeRecord.fromJson(r)).toList();
    } catch (e) {
      lastError = '$e';
      // ignore: avoid_print
      print('getRecords failed: $e');
      return [];
    }
  }

  Future<void> removeRecord(int id) async {
    try {
      final db = await database;
      await db.delete('practice_records', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      lastError = '$e';
      // ignore: avoid_print
      print('removeRecord failed: $e');
    }
  }

  Future<void> clearRecords() async {
    try {
      final db = await database;
      await db.delete('practice_records');
    } catch (e) {
      lastError = '$e';
      // ignore: avoid_print
      print('clearRecords failed: $e');
    }
  }
}

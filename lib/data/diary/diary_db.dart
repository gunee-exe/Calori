/// The writable on-device database: profile, entries, items, learned values.
///
/// Deliberately a *separate* Drift database from `foods.sqlite`, with its own
/// executor and its own `schemaVersion`. They are never `ATTACH`ed together —
/// see `05-build-plan.md` for the reasoning. In short: there are no cross-database
/// joins to serve, and Drift generates one `Migrator` per database, so attaching
/// would make the diary's migrator try to create the `foods` tables.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

// The generated part file references these enum types directly, and a part
// resolves names against its own library rather than through tables.dart.
import '../../domain/models/enums.dart';
import 'tables.dart';

part 'diary_db.g.dart';

@DriftDatabase(tables: [Profiles, Entries, EntryItems, FoodCacheEntries])
class DiaryDb extends _$DiaryDb {
  DiaryDb() : super(_openDiary());

  /// For tests: an in-memory database with no file backing.
  DiaryDb.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // The calendar reads a whole month at a time and the day view reads a
      // single day; both go through dayKey, so it carries the only index that
      // materially affects perceived speed.
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_day ON entries (day_key)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entry_items_entry '
        'ON entry_items (entry_id)',
      );
    },
    beforeOpen: (details) async {
      // Off by default in SQLite. Without it, the ON DELETE CASCADE from
      // entries to entry_items is silently ignored and deleting an entry
      // orphans its items.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openDiary() {
  return LazyDatabase(() async {
    // Documents, not support: this is irreplaceable user data and *should* be
    // picked up by Android Auto Backup. `foods.sqlite` takes the opposite
    // choice for the opposite reason.
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'diary.sqlite'));

    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
    return NativeDatabase.createInBackground(file);
  });
}

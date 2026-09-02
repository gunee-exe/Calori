/// The bundled, read-only food database.
///
/// Ships as `assets/db/foods.sqlite`, built on desktop by
/// `tools/build_foods_db` (see `03-food-data.md`). It is copied out of the
/// bundle on first launch and then only ever read.
///
/// Separate Drift database from [DiaryDb], with its own executor. Never
/// `ATTACH`ed to it: there is nothing to join across them, the diary
/// denormalises macros at write time, and Drift generates one migrator per
/// database.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

part 'foods_db.g.dart';

/// Bump whenever `assets/db/foods.sqlite` is rebuilt.
///
/// The version is carried in the on-disk *filename*, so a bump is what triggers
/// the re-copy. Sidecar stamp files and SharedPreferences both have a torn-write
/// failure mode — stamp written, copy incomplete — that a filename cannot have.
const kFoodsAssetVersion = 3;

const _assetPath = 'assets/db/foods.sqlite';

@DriftDatabase(include: {'foods.drift'})
class FoodsDb extends _$FoodsDb {
  FoodsDb() : super(openFoodsConnection());

  /// For tests: point at an already-open executor holding a fixture database.
  FoodsDb.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // This database ships finished. There is nothing to create and nothing to
    // migrate; if drift ever thinks otherwise, the asset copy has gone wrong
    // and failing loudly beats silently creating empty tables.
    onCreate: (m) async {
      throw StateError(
        'foods.sqlite was opened but appears empty. The asset copy failed, or '
        'assets/db/foods.sqlite has not been built yet — run '
        'tools/build_foods_db.',
      );
    },
  );
}

/// Opens the food database, seeding it from the app bundle on first use.
QueryExecutor openFoodsConnection() {
  return LazyDatabase(() async {
    // Support, not documents: this is a regenerable blob. Putting it in
    // documents would enrol it in Android Auto Backup and burn a large slice of
    // the user's 25 MB quota backing up a file that ships in every APK.
    //
    // Not the cache directory either — Android evicts that under storage
    // pressure, and food search would silently stop working.
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'foods_v$kFoodsAssetVersion.sqlite'));

    if (!file.existsSync()) {
      await _copyAssetTo(file);
      await _reapOldVersions(dir, keep: file.path);
    }

    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

    return NativeDatabase.createInBackground(
      file,
      // Drift writes `user_version` on open unless told not to, which fails
      // against the read-only connection configured below.
      enableMigrations: false,
      // Lets concurrent as-you-type searches run in parallel rather than
      // queueing behind one another.
      readPool: 2,
      setup: (db) => db.execute('PRAGMA query_only = ON;'),
    );
  });
}

/// Copies the bundled asset to [target] via a temporary file.
///
/// The temp-then-rename is the part that matters. Writing straight to the final
/// path means a crash or a kill mid-copy leaves a truncated file that the
/// `existsSync()` check above will happily trust on the next launch, leaving
/// search permanently broken for that install. `rename` is atomic within a
/// filesystem, so the final path only ever appears complete.
Future<void> _copyAssetTo(File target) async {
  final tmp = File('${target.path}.tmp');
  final blob = await rootBundle.load(_assetPath);

  await tmp.writeAsBytes(
    blob.buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes),
    flush: true,
  );
  await tmp.rename(target.path);
}

/// Deletes superseded `foods_v*.sqlite` copies left by earlier app versions.
Future<void> _reapOldVersions(Directory dir, {required String keep}) async {
  await for (final entity in dir.list()) {
    if (entity is! File) continue;

    final name = p.basename(entity.path);
    if (!name.startsWith('foods_v')) continue;
    if (entity.path == keep) continue;

    try {
      await entity.delete();
    } on FileSystemException {
      // A stale copy we cannot remove is wasted space, not a failure worth
      // blocking startup over.
    }
  }
}

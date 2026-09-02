/// The diary migrations, v1 -> v2 -> v3.
///
/// Tested against a database actually created at v1, not a fresh one. A fresh
/// install runs `onCreate` and never touches `onUpgrade`, so testing that way
/// proves the new columns exist and proves nothing at all about the upgrade
/// path every existing install will take.
library;

import 'dart:io';

import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/repositories/diary_repository_impl.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// The `profiles` table exactly as schema 1 left it: no override columns, no
/// units column.
const _v1Profiles = '''
CREATE TABLE profiles (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  sex TEXT NOT NULL,
  age INTEGER NOT NULL,
  height_cm REAL NOT NULL,
  weight_kg REAL NOT NULL,
  target_weight_kg REAL NOT NULL,
  activity_level TEXT NOT NULL,
  target_date INTEGER,
  daily_kcal INTEGER NOT NULL,
  daily_protein_g INTEGER NOT NULL,
  daily_carbs_g INTEGER NOT NULL,
  daily_fat_g INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''';


/// `profiles` as schema 2 left it: the override columns and a single
/// `uses_imperial` flag covering height *and* weight, but no `uses_feet`.
const _v2Profiles = '''
CREATE TABLE profiles (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  sex TEXT NOT NULL,
  age INTEGER NOT NULL,
  height_cm REAL NOT NULL,
  weight_kg REAL NOT NULL,
  target_weight_kg REAL NOT NULL,
  activity_level TEXT NOT NULL,
  target_date INTEGER,
  daily_kcal INTEGER NOT NULL,
  daily_protein_g INTEGER NOT NULL,
  daily_carbs_g INTEGER NOT NULL,
  daily_fat_g INTEGER NOT NULL,
  kcal_override INTEGER,
  protein_override_g INTEGER,
  uses_imperial INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
)''';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('calori_migration');
    file = File(p.join(dir.path, 'diary.sqlite'));

    final raw = sqlite3.open(file.path);
    raw.execute(_v1Profiles);
    raw.execute('''
INSERT INTO profiles (
  sex, age, height_cm, weight_kg, target_weight_kg, activity_level,
  daily_kcal, daily_protein_g, daily_carbs_g, daily_fat_g, updated_at
) VALUES ('male', 30, 178, 78, 70, 'moderate', 2070, 140, 247, 58, 0)''');
    raw.execute('PRAGMA user_version = 1');
    raw.close();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('a v1 diary gains the new columns and keeps its profile', () async {
    final db = DiaryDb.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final profile = await DiaryRepositoryImpl(db).profile();

    // Everything that was there is still there. A migration that quietly reset
    // someone's goal would be worse than no migration.
    expect(profile, isNotNull);
    expect(profile!.sex, Sex.male);
    expect(profile.weightKg, 78);
    expect(profile.dailyKcal, 2070);
    expect(profile.dailyProteinG, 140);

    // And the new columns read as their "nothing was set" values rather than
    // as an error, which is what lets a pre-existing row work untouched.
    expect(profile.kcalOverride, isNull);
    expect(profile.proteinOverrideG, isNull);
    expect(profile.usesPounds, isFalse);
    expect(profile.usesFeet, isFalse);
    expect(profile.hasManualGoals, isFalse);
  });

  test('the upgraded database can then store an override', () async {
    final db = DiaryDb.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final repository = DiaryRepositoryImpl(db);
    final before = (await repository.profile())!;

    await repository.saveProfile(
      UserProfile(
        sex: before.sex,
        age: before.age,
        heightCm: before.heightCm,
        weightKg: before.weightKg,
        targetWeightKg: before.targetWeightKg,
        activity: before.activity,
        dailyKcal: 2400,
        dailyProteinG: 180,
        dailyCarbsG: 200,
        dailyFatG: 70,
        kcalOverride: 2400,
        proteinOverrideG: 180,
        usesPounds: true,
        usesFeet: true,
      ),
    );

    final after = (await repository.profile())!;
    expect(after.kcalOverride, 2400);
    expect(after.proteinOverrideG, 180);
    expect(after.hasManualGoals, isTrue);
    expect(after.usesPounds, isTrue);
    expect(after.usesFeet, isTrue);
  });

  test('reopening an already-migrated database is a no-op', () async {
    final first = DiaryDb.forTesting(NativeDatabase(file));
    await DiaryRepositoryImpl(first).profile();
    await first.close();

    // addColumn on a column that already exists is an error, so the version
    // guard has to hold on the second open as well as the first.
    final second = DiaryDb.forTesting(NativeDatabase(file));
    addTearDown(second.close);
    expect(await DiaryRepositoryImpl(second).profile(), isNotNull);
  });

  /// Rewrites the fixture as a schema-2 database with `uses_imperial` set.
  void seedV2({required bool imperial}) {
    file.deleteSync();
    final raw = sqlite3.open(file.path);
    raw.execute(_v2Profiles);
    raw.execute('''
INSERT INTO profiles (
  sex, age, height_cm, weight_kg, target_weight_kg, activity_level,
  daily_kcal, daily_protein_g, daily_carbs_g, daily_fat_g, uses_imperial,
  updated_at
) VALUES ('female', 41, 165, 68, 62, 'light', 1800, 120, 180, 60, ${imperial ? 1 : 0}, 0)''');
    raw.execute('PRAGMA user_version = 2');
    raw.close();
  }

  test('a v2 imperial profile keeps feet as well as pounds', () async {
    seedV2(imperial: true);

    final db = DiaryDb.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final profile = (await DiaryRepositoryImpl(db).profile())!;

    // The v2 flag meant both. Adding uses_feet with a plain false default would
    // have silently moved this user's height back to centimetres the next time
    // they opened the Goal screen, which is the kind of change nobody reports
    // and everybody notices.
    expect(profile.usesPounds, isTrue);
    expect(profile.usesFeet, isTrue, reason: 'the old flag was not carried over');
  });

  test('a v2 metric profile stays metric on both', () async {
    seedV2(imperial: false);

    final db = DiaryDb.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final profile = (await DiaryRepositoryImpl(db).profile())!;
    expect(profile.usesPounds, isFalse);
    expect(profile.usesFeet, isFalse);
    expect(profile.weightKg, 68);
  });
}

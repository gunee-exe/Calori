/// The v1 -> v2 diary migration.
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
    expect(profile.usesImperial, isFalse);
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
        usesImperial: true,
      ),
    );

    final after = (await repository.profile())!;
    expect(after.kcalOverride, 2400);
    expect(after.proteinOverrideG, 180);
    expect(after.hasManualGoals, isTrue);
    expect(after.usesImperial, isTrue);
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
}

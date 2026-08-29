/// Database and repository providers.
///
/// The two databases are `keepAlive` because opening them is expensive — the
/// foods database copies a 3 MB asset out of the bundle on first run — and
/// because their lifetime is the app's, not any one screen's.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/diary_repository.dart';
import '../domain/repositories/food_repository.dart';
import 'diary/diary_db.dart';
import 'foods/foods_db.dart';
import 'repositories/diary_repository_impl.dart';
import 'repositories/food_repository_impl.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
FoodsDb foodsDb(Ref ref) {
  final db = FoodsDb();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
DiaryDb diaryDb(Ref ref) {
  final db = DiaryDb();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
FoodRepository foodRepository(Ref ref) =>
    FoodRepositoryImpl(ref.watch(foodsDbProvider));

@Riverpod(keepAlive: true)
DiaryRepository diaryRepository(Ref ref) =>
    DiaryRepositoryImpl(ref.watch(diaryDbProvider));

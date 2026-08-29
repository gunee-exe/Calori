// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(foodsDb)
final foodsDbProvider = FoodsDbProvider._();

final class FoodsDbProvider
    extends $FunctionalProvider<FoodsDb, FoodsDb, FoodsDb>
    with $Provider<FoodsDb> {
  FoodsDbProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodsDbProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodsDbHash();

  @$internal
  @override
  $ProviderElement<FoodsDb> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FoodsDb create(Ref ref) {
    return foodsDb(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodsDb value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodsDb>(value),
    );
  }
}

String _$foodsDbHash() => r'41c5dc019ea3629c7c369ba6dafa95fd21818c47';

@ProviderFor(diaryDb)
final diaryDbProvider = DiaryDbProvider._();

final class DiaryDbProvider
    extends $FunctionalProvider<DiaryDb, DiaryDb, DiaryDb>
    with $Provider<DiaryDb> {
  DiaryDbProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDbProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDbHash();

  @$internal
  @override
  $ProviderElement<DiaryDb> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiaryDb create(Ref ref) {
    return diaryDb(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryDb value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryDb>(value),
    );
  }
}

String _$diaryDbHash() => r'3a085ba77a2e827ec0269d8a7ee242a2201d6947';

@ProviderFor(foodRepository)
final foodRepositoryProvider = FoodRepositoryProvider._();

final class FoodRepositoryProvider
    extends $FunctionalProvider<FoodRepository, FoodRepository, FoodRepository>
    with $Provider<FoodRepository> {
  FoodRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodRepositoryHash();

  @$internal
  @override
  $ProviderElement<FoodRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FoodRepository create(Ref ref) {
    return foodRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodRepository>(value),
    );
  }
}

String _$foodRepositoryHash() => r'5f047000397c7b1dd6e72c1b44bca0c67349c5bf';

@ProviderFor(diaryRepository)
final diaryRepositoryProvider = DiaryRepositoryProvider._();

final class DiaryRepositoryProvider
    extends
        $FunctionalProvider<DiaryRepository, DiaryRepository, DiaryRepository>
    with $Provider<DiaryRepository> {
  DiaryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryRepositoryHash();

  @$internal
  @override
  $ProviderElement<DiaryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiaryRepository create(Ref ref) {
    return diaryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryRepository>(value),
    );
  }
}

String _$diaryRepositoryHash() => r'16d64d955a3d9b353a0a7c3dc6008fe07c067b37';

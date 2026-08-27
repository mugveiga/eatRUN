// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foods_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single app-wide database instance. `keepAlive` so it isn't torn down
/// between screens. This is DI: everything downstream `watch`es it.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Single app-wide database instance. `keepAlive` so it isn't torn down
/// between screens. This is DI: everything downstream `watch`es it.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Single app-wide database instance. `keepAlive` so it isn't torn down
  /// between screens. This is DI: everything downstream `watch`es it.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

@ProviderFor(foodsRepository)
final foodsRepositoryProvider = FoodsRepositoryProvider._();

final class FoodsRepositoryProvider
    extends
        $FunctionalProvider<FoodsRepository, FoodsRepository, FoodsRepository>
    with $Provider<FoodsRepository> {
  FoodsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FoodsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FoodsRepository create(Ref ref) {
    return foodsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodsRepository>(value),
    );
  }
}

String _$foodsRepositoryHash() => r'a58db68195d1c1a2c57a024dacd9eeb968f2b050';

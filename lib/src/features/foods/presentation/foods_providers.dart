import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../data/foods_dao.dart';
import '../data/foods_repository.dart';

part 'foods_providers.g.dart';

/// Single app-wide database instance. `keepAlive` so it isn't torn down
/// between screens. This is DI: everything downstream `watch`es it.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
FoodsRepository foodsRepository(Ref ref) {
  return FoodsRepository(FoodsDao(ref.watch(appDatabaseProvider)));
}

/// Reactive list of foods. Hand-written (not `@riverpod`) because its type
/// `Food` is a Drift-generated part-file class, which the Riverpod generator
/// can't resolve. Manual providers skip that codegen pass.
final foodsListProvider = StreamProvider.autoDispose<List<Food>>((ref) {
  return ref.watch(foodsRepositoryProvider).watchFoods();
});

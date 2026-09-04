import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../../../core/database/sync.dart';
import '../../../core/database/tables.dart';

part 'foods_dao.g.dart';

@DriftAccessor(tables: [Foods])
class FoodsDao extends DatabaseAccessor<AppDatabase> with _$FoodsDaoMixin {
  FoodsDao(super.db);

  /// Live list of non-deleted foods, alphabetical. Emits on every change.
  Stream<List<Food>> watchFoods() {
    return (select(foods)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  Future<Food?> findById(String id) {
    return (select(foods)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(FoodsCompanion food) {
    return into(foods).insertOnConflictUpdate(food);
  }

  /// Soft delete: keep the row, mark it gone and dirty so sync can push it.
  Future<void> softDelete(String id) {
    return (update(foods)..where((t) => t.id.equals(id))).write(
      FoodsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }
}

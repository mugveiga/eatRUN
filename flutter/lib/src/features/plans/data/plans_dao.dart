import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../../../core/database/sync.dart';
import '../../../core/database/tables.dart';

part 'plans_dao.g.dart';

@DriftAccessor(tables: [Plans, PlanItems])
class PlansDao extends DatabaseAccessor<AppDatabase> with _$PlansDaoMixin {
  PlansDao(super.db);

  /// Live list of non-deleted plans, most recent first.
  Stream<List<Plan>> watchPlans() {
    return (select(plans)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<Plan?> findPlan(String id) {
    return (select(plans)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Plan?> watchPlan(String id) {
    return (select(plans)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Set the intake-tracking mode and interval (chosen after plan creation).
  Future<void> updateIntake(String id, PlanType planType, double interval) {
    return (update(plans)..where((t) => t.id.equals(id))).write(
      PlansCompanion(
        planType: Value(planType),
        intakeInterval: Value(interval),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  /// Live timeline items for a plan, ordered along the 0 → length axis.
  Stream<List<PlanItem>> watchItems(String planId) {
    return (select(planItems)
          ..where((t) => t.planId.equals(planId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.offsetLength)]))
        .watch();
  }

  Future<void> upsertPlan(PlansCompanion plan) {
    return into(plans).insertOnConflictUpdate(plan);
  }

  Future<void> upsertItem(PlanItemsCompanion item) {
    return into(planItems).insertOnConflictUpdate(item);
  }

  /// Fine-tune a placed item's position and quantity.
  Future<void> updateItem(String id, double offsetLength, double quantity) {
    return (update(planItems)..where((t) => t.id.equals(id))).write(
      PlanItemsCompanion(
        offsetLength: Value(offsetLength),
        quantity: Value(quantity),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> softDeleteItem(String id) {
    return (update(planItems)..where((t) => t.id.equals(id))).write(
      PlanItemsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  /// Soft-delete a plan and all its items together, so sync never sees a
  /// plan gone but its items lingering.
  Future<void> softDeletePlan(String id) {
    return transaction(() async {
      final now = DateTime.now();
      await (update(plans)..where((t) => t.id.equals(id))).write(
        PlansCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
      await (update(planItems)..where((t) => t.planId.equals(id))).write(
        PlanItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
    });
  }
}

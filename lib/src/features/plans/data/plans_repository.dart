import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/database/sync.dart';
import '../../../core/database/tables.dart';
import 'plans_dao.dart';

/// Offline-first seam for plans and their timeline items. Local-only today;
/// remote read/write and sync queueing land here later.
class PlansRepository {
  PlansRepository(this._dao, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final PlansDao _dao;
  final Uuid _uuid;

  Stream<List<Plan>> watchPlans() => _dao.watchPlans();

  Future<Plan?> findPlan(String id) => _dao.findPlan(id);

  Stream<List<PlanItem>> watchItems(String planId) => _dao.watchItems(planId);

  /// Create (id null) or update a plan. Returns the plan's id so callers can
  /// attach items to a freshly created plan.
  Future<String> savePlan({
    String? id,
    required String name,
    required DateTime date,
    required ActivityType activityType,
    required double distanceKm,
    required int durationMinutes,
    double targetCarbsPerHour = 0,
    double targetSodiumPerHour = 0,
    double targetCaffeinePerHour = 0,
    PlanType? planType,
    double? intakeInterval,
    String? comments,
  }) async {
    final planId = id ?? _uuid.v4();
    await _dao.upsertPlan(
      PlansCompanion(
        id: Value(planId),
        name: Value(name),
        date: Value(date),
        activityType: Value(activityType),
        distanceKm: Value(distanceKm),
        durationMinutes: Value(durationMinutes),
        targetCarbsPerHour: Value(targetCarbsPerHour),
        targetSodiumPerHour: Value(targetSodiumPerHour),
        targetCaffeinePerHour: Value(targetCaffeinePerHour),
        planType: Value(planType),
        intakeInterval: Value(intakeInterval),
        comments: Value(comments),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
    return planId;
  }

  /// Add (id null) or update one food entry on a plan's timeline.
  Future<void> saveItem({
    String? id,
    required String planId,
    required String foodId,
    required double offsetLength,
    double quantity = 1,
  }) {
    return _dao.upsertItem(
      PlanItemsCompanion(
        id: Value(id ?? _uuid.v4()),
        planId: Value(planId),
        foodId: Value(foodId),
        offsetLength: Value(offsetLength),
        quantity: Value(quantity),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> deletePlan(String id) => _dao.softDeletePlan(id);

  Future<void> deleteItem(String id) => _dao.softDeleteItem(id);
}

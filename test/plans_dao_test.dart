import 'package:drift/native.dart';
import 'package:eatrun/src/core/database/database.dart';
import 'package:eatrun/src/core/database/tables.dart';
import 'package:eatrun/src/features/plans/data/plans_dao.dart';
import 'package:eatrun/src/features/plans/data/plans_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save a plan with a timeline item, then watch them', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PlansRepository(PlansDao(db));

    // A plan item references a food, so seed one.
    await db.into(db.foods).insert(
          FoodsCompanion.insert(
            id: 'food-1',
            name: 'Gel',
            updatedAt: DateTime.now(),
          ),
        );

    final planId = await repo.savePlan(
      name: 'Long run',
      date: DateTime(2026, 8, 30),
      activityType: ActivityType.run,
      distanceKm: 30,
      durationMinutes: 150,
      targetCarbsPerHour: 60,
    );
    await repo.saveItem(planId: planId, foodId: 'food-1', offsetLength: 10);

    final plans = await repo.watchPlans().first;
    expect(plans, hasLength(1));
    expect(plans.single.name, 'Long run');
    expect(plans.single.activityType, ActivityType.run);
    expect(plans.single.distanceKm, 30);
    expect(plans.single.planType, isNull); // set later, at matching

    final items = await repo.watchItems(planId).first;
    expect(items, hasLength(1));
    expect(items.single.offsetLength, 10);
    expect(items.single.quantity, 1); // default

    // Deleting the plan soft-deletes its items too.
    await repo.deletePlan(planId);
    expect(await repo.watchPlans().first, isEmpty);
    expect(await repo.watchItems(planId).first, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 30)));
}

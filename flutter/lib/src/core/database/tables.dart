import 'package:drift/drift.dart';

import 'sync.dart';

/// How intake is tracked along the plan: by distance or by time. Chosen at
/// the food-matching step, so nullable on the plan until then.
enum PlanType { distance, duration }

/// The kind of workout. Drives whether the third pace control is min/km (run)
/// or km/h (bike).
enum ActivityType { run, bike }

/// A food/gel/drink the user can consume. Nutrition is per single serving.
class Foods extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get photoPath => text().nullable()();
  IntColumn get carbsGrams => integer().withDefault(const Constant(0))();
  IntColumn get sodiumMg => integer().withDefault(const Constant(0))();
  IntColumn get caffeineMg => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

/// A planned workout with per-hour fueling targets.
class Plans extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  DateTimeColumn get date => dateTime()();
  IntColumn get activityType => intEnum<ActivityType>()();

  /// Both are always set; pace/speed is derived from them (distance ÷ time).
  RealColumn get distanceKm => real()();
  IntColumn get durationMinutes => integer()();

  RealColumn get targetCarbsPerHour => real().withDefault(const Constant(0))();
  RealColumn get targetSodiumPerHour => real().withDefault(const Constant(0))();
  RealColumn get targetCaffeinePerHour =>
      real().withDefault(const Constant(0))();

  /// Intake-tracking mode, chosen at the matching step (null until then).
  IntColumn get planType => intEnum<PlanType>().nullable()();

  /// Planned gap between intakes, in [planType]'s unit. Set at matching.
  RealColumn get intakeInterval => real().nullable()();

  /// Free-text notes, before or after the activity.
  TextColumn get comments => text().nullable()();
}

/// One consumption on a plan's timeline (0 → distance or duration).
class PlanItems extends Table with SyncColumns {
  TextColumn get planId =>
      text().references(Plans, #id, onDelete: KeyAction.cascade)();
  TextColumn get foodId => text().references(Foods, #id)();

  /// Position on the timeline, in the plan's unit (km or minutes).
  RealColumn get offsetLength => real()();

  /// Number of servings consumed at this point.
  RealColumn get quantity => real().withDefault(const Constant(1))();
}

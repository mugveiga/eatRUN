import 'package:drift/drift.dart';

import 'sync.dart';

/// Whether a plan is bounded by distance or by time.
enum PlanType { distance, duration }

/// A food/gel/drink the user can consume. Nutrition is per single serving.
class Foods extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get photoPath => text().nullable()();
  RealColumn get carbsGrams => real().withDefault(const Constant(0))();
  RealColumn get sodiumMg => real().withDefault(const Constant(0))();
  RealColumn get caffeineMg => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

/// A planned workout with per-hour fueling targets.
class Plans extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  DateTimeColumn get date => dateTime()();
  IntColumn get planType => intEnum<PlanType>()();

  /// The plan's extent, read in [planType]'s unit: km for distance,
  /// minutes for duration.
  RealColumn get length => real()();

  RealColumn get targetCarbsPerHour => real().withDefault(const Constant(0))();
  RealColumn get targetSodiumPerHour => real().withDefault(const Constant(0))();
  RealColumn get targetCaffeinePerHour =>
      real().withDefault(const Constant(0))();

  /// Planned gap between intakes, in the plan's unit (km or minutes).
  /// Null if there's no fixed gap.
  RealColumn get intakeInterval => real().nullable()();

  /// For a distance plan, bridges km → time so the per-hour targets can be
  /// computed. Null for a duration plan (length is already time). The UI can
  /// let the user enter this as pace (min/km) or speed (km/h) and convert.
  IntColumn get expectedDurationMinutes => integer().nullable()();

  /// Free-text notes, before or after the activity.
  TextColumn get comments => text().nullable()();
}

/// One consumption on a plan's 0 → [Plans.length] timeline.
class PlanItems extends Table with SyncColumns {
  TextColumn get planId => text().references(Plans, #id)();
  TextColumn get foodId => text().references(Foods, #id)();

  /// Position on the timeline, in the plan's unit (km or minutes).
  RealColumn get offsetLength => real()();

  /// Number of servings consumed at this point.
  RealColumn get quantity => real().withDefault(const Constant(1))();
}

import { integer, real, sqliteTable, text } from 'drizzle-orm/sqlite-core';

/// Union types stored as text (SQLite has no native enums).
export type ActivityType = 'run' | 'bike';
export type PlanType = 'distance' | 'duration';
export type SyncStatus = 'pending' | 'synced';

/// Sync metadata shared by every table — offline-first, so a backend can be
/// added later without a migration.
/// - id: client-generated UUID (globally unique; survives sync)
/// - updatedAt: last-write-wins conflict handling
/// - deletedAt: soft delete (sync "deleted", never a vanished row)
/// - syncStatus: 'pending' until a backend confirms 'synced'
/// - userId: null until login scopes data per user
const syncColumns = {
  id: text('id').primaryKey(),
  updatedAt: integer('updated_at', { mode: 'timestamp_ms' }).notNull(),
  deletedAt: integer('deleted_at', { mode: 'timestamp_ms' }),
  syncStatus: text('sync_status').$type<SyncStatus>().notNull().default('pending'),
  userId: text('user_id'),
};

/// A food/gel/drink. Nutrition is per single serving.
export const foods = sqliteTable('foods', {
  ...syncColumns,
  name: text('name').notNull(),
  photoUri: text('photo_uri'),
  carbsGrams: integer('carbs_grams').notNull().default(0),
  sodiumMg: integer('sodium_mg').notNull().default(0),
  caffeineMg: integer('caffeine_mg').notNull().default(0),
  notes: text('notes'),
});

/// A planned workout with per-hour fueling targets. `planType`/`intakeInterval`
/// are chosen later (the intake-matching step), so they're nullable.
export const plans = sqliteTable('plans', {
  ...syncColumns,
  name: text('name').notNull(),
  date: integer('date', { mode: 'timestamp_ms' }).notNull(),
  activityType: text('activity_type').$type<ActivityType>().notNull(),
  distanceKm: real('distance_km').notNull(),
  durationMinutes: integer('duration_minutes').notNull(),
  targetCarbsPerHour: real('target_carbs_per_hour').notNull().default(0),
  targetSodiumPerHour: real('target_sodium_per_hour').notNull().default(0),
  targetCaffeinePerHour: real('target_caffeine_per_hour').notNull().default(0),
  planType: text('plan_type').$type<PlanType>(),
  intakeInterval: real('intake_interval'),
  comments: text('comments'),
});

/// One food placed on a plan's timeline at `offsetLength` (km or minutes,
/// per the plan's `planType`). Deleting a plan cascades to its items.
export const planItems = sqliteTable('plan_items', {
  ...syncColumns,
  planId: text('plan_id')
    .notNull()
    .references(() => plans.id, { onDelete: 'cascade' }),
  foodId: text('food_id')
    .notNull()
    .references(() => foods.id),
  offsetLength: real('offset_length').notNull(),
  quantity: real('quantity').notNull().default(1),
});

export type Food = typeof foods.$inferSelect;
export type NewFood = typeof foods.$inferInsert;
export type Plan = typeof plans.$inferSelect;
export type NewPlan = typeof plans.$inferInsert;
export type PlanItem = typeof planItems.$inferSelect;
export type NewPlanItem = typeof planItems.$inferInsert;

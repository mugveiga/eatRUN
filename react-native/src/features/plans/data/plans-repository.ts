import { eq } from 'drizzle-orm';
import * as Crypto from 'expo-crypto';

import { db } from '@/core/db/client';
import {
  planItems,
  plans,
  type ActivityType,
  type Plan,
  type PlanType,
} from '@/core/db/schema';

export type PlanInput = {
  id?: string;
  name: string;
  date: Date;
  activityType: ActivityType;
  distanceKm: number;
  durationMinutes: number;
  targetCarbsPerHour?: number;
  targetSodiumPerHour?: number;
  targetCaffeinePerHour?: number;
  planType?: PlanType | null;
  intakeInterval?: number | null;
  comments?: string | null;
};

export async function findPlan(id: string): Promise<Plan | undefined> {
  const rows = await db.select().from(plans).where(eq(plans.id, id)).limit(1);
  return rows.at(0);
}

/// Create (id undefined) or update a plan. Returns the id.
export async function savePlan(input: PlanInput): Promise<string> {
  const id = input.id ?? Crypto.randomUUID();
  const now = new Date();
  const fields = {
    name: input.name,
    date: input.date,
    activityType: input.activityType,
    distanceKm: input.distanceKm,
    durationMinutes: input.durationMinutes,
    targetCarbsPerHour: input.targetCarbsPerHour ?? 0,
    targetSodiumPerHour: input.targetSodiumPerHour ?? 0,
    targetCaffeinePerHour: input.targetCaffeinePerHour ?? 0,
    planType: input.planType ?? null,
    intakeInterval: input.intakeInterval ?? null,
    comments: input.comments ?? null,
    updatedAt: now,
    syncStatus: 'pending' as const,
  };
  await db
    .insert(plans)
    .values({ id, ...fields })
    .onConflictDoUpdate({ target: plans.id, set: fields });
  return id;
}

/// Soft delete a plan and its timeline items together.
export async function deletePlan(id: string): Promise<void> {
  const now = new Date();
  const gone = { deletedAt: now, updatedAt: now, syncStatus: 'pending' as const };
  await db.update(plans).set(gone).where(eq(plans.id, id));
  await db.update(planItems).set(gone).where(eq(planItems.planId, id));
}

/// Choose how a plan's intake is tracked (by distance or time) and the
/// interval between suggested fuel points. Unlocks the timeline.
export async function setIntakeTracking(args: {
  id: string;
  planType: PlanType;
  interval: number;
}): Promise<void> {
  await db
    .update(plans)
    .set({
      planType: args.planType,
      intakeInterval: args.interval,
      updatedAt: new Date(),
      syncStatus: 'pending',
    })
    .where(eq(plans.id, args.id));
}

/// Place a food on a plan's timeline at an offset (km or min). Returns the id.
export async function saveItem(args: {
  planId: string;
  foodId: string;
  offsetLength: number;
  quantity?: number;
}): Promise<string> {
  const id = Crypto.randomUUID();
  await db.insert(planItems).values({
    id,
    planId: args.planId,
    foodId: args.foodId,
    offsetLength: args.offsetLength,
    quantity: args.quantity ?? 1,
    updatedAt: new Date(),
    syncStatus: 'pending',
  });
  return id;
}

/// Fine-tune a placed item's position and servings.
export async function updateItem(args: {
  id: string;
  offsetLength: number;
  quantity: number;
}): Promise<void> {
  await db
    .update(planItems)
    .set({
      offsetLength: args.offsetLength,
      quantity: args.quantity,
      updatedAt: new Date(),
      syncStatus: 'pending',
    })
    .where(eq(planItems.id, args.id));
}

/// Soft delete a single timeline item.
export async function deleteItem(id: string): Promise<void> {
  const now = new Date();
  await db
    .update(planItems)
    .set({ deletedAt: now, updatedAt: now, syncStatus: 'pending' })
    .where(eq(planItems.id, id));
}

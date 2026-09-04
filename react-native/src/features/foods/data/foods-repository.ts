import { eq } from 'drizzle-orm';
import * as Crypto from 'expo-crypto';

import { db } from '@/core/db/client';
import { foods, type Food } from '@/core/db/schema';

export type FoodInput = {
  id?: string;
  name: string;
  photoUri?: string | null;
  carbsGrams?: number;
  sodiumMg?: number;
  caffeineMg?: number;
  notes?: string | null;
};

export async function findFood(id: string): Promise<Food | undefined> {
  const rows = await db.select().from(foods).where(eq(foods.id, id)).limit(1);
  return rows.at(0);
}

/// Create (id undefined) or update a food. Stamps sync metadata.
export async function saveFood(input: FoodInput): Promise<string> {
  const id = input.id ?? Crypto.randomUUID();
  const now = new Date();
  const fields = {
    name: input.name,
    photoUri: input.photoUri ?? null,
    carbsGrams: input.carbsGrams ?? 0,
    sodiumMg: input.sodiumMg ?? 0,
    caffeineMg: input.caffeineMg ?? 0,
    notes: input.notes ?? null,
    updatedAt: now,
    syncStatus: 'pending' as const,
  };
  await db
    .insert(foods)
    .values({ id, ...fields })
    .onConflictDoUpdate({ target: foods.id, set: fields });
  return id;
}

/// Soft delete: keep the row, mark it gone and dirty so sync can push it.
export async function deleteFood(id: string): Promise<void> {
  const now = new Date();
  await db
    .update(foods)
    .set({ deletedAt: now, updatedAt: now, syncStatus: 'pending' })
    .where(eq(foods.id, id));
}

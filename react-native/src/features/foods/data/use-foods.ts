import { isNull } from 'drizzle-orm';
import { useLiveQuery } from 'drizzle-orm/expo-sqlite';

import { db } from '@/core/db/client';
import { foods } from '@/core/db/schema';

/// Reactive list of non-deleted foods, alphabetical. Re-runs on any DB change
/// (the analog of Drift's watch() streams).
export function useFoods() {
  return useLiveQuery(
    db.select().from(foods).where(isNull(foods.deletedAt)).orderBy(foods.name),
  );
}

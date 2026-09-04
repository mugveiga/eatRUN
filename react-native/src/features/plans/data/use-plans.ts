import { desc, eq, isNull } from 'drizzle-orm';
import { useLiveQuery } from 'drizzle-orm/expo-sqlite';

import { db } from '@/core/db/client';
import { plans } from '@/core/db/schema';

/// Reactive list of non-deleted plans, most recent first.
export function usePlans() {
  return useLiveQuery(
    db.select().from(plans).where(isNull(plans.deletedAt)).orderBy(desc(plans.date)),
  );
}

/// Reactive single plan (data[0] is the plan, or undefined).
export function usePlan(id: string) {
  return useLiveQuery(db.select().from(plans).where(eq(plans.id, id)));
}

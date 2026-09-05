import { and, asc, desc, eq, isNull } from 'drizzle-orm';
import { useLiveQuery } from 'drizzle-orm/expo-sqlite';

import { db } from '@/core/db/client';
import { planItems, plans } from '@/core/db/schema';

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

/// Reactive list of a plan's non-deleted timeline items, earliest offset first.
export function usePlanItems(planId: string) {
  return useLiveQuery(
    db
      .select()
      .from(planItems)
      .where(and(eq(planItems.planId, planId), isNull(planItems.deletedAt)))
      .orderBy(asc(planItems.offsetLength)),
  );
}

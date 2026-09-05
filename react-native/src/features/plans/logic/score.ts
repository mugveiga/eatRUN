import type { Food, PlanItem } from '@/core/db/schema';

export type Nutrients = { carbs: number; sodium: number; caffeine: number };

/// Roll placed items' nutrition (scaled by servings) into per-hour rates, so
/// they compare directly against the plan's per-hour targets.
export function perHourTotals(
  items: PlanItem[],
  foodsById: Map<string, Food>,
  durationMinutes: number,
): Nutrients {
  let carbs = 0;
  let sodium = 0;
  let caffeine = 0;
  for (const it of items) {
    const f = foodsById.get(it.foodId);
    if (!f) continue;
    carbs += f.carbsGrams * it.quantity;
    sodium += f.sodiumMg * it.quantity;
    caffeine += f.caffeineMg * it.quantity;
  }
  const hours = durationMinutes / 60;
  const per = (total: number): number => (hours > 0 ? total / hours : 0);
  return { carbs: per(carbs), sodium: per(sodium), caffeine: per(caffeine) };
}

/// Progress of actual against target, clamped to 0..1. With no target, any
/// intake reads as full; none reads as empty.
export function scoreRatio(actual: number, target: number): number {
  if (target > 0) return Math.min(Math.max(actual / target, 0), 1);
  return actual > 0 ? 1 : 0;
}

const EPS = 1e-6;

/// Suggested fuel-point offsets for a fresh timeline: interval, 2·interval, …
/// up to the workout length (km or minutes). Capped so a tiny interval can't
/// generate an unbounded list.
export function seedSlots(interval: number, length: number): number[] {
  if (interval <= 0) return [];
  const out: number[] = [];
  for (let o = interval; o <= length + EPS && out.length < 200; o += interval) {
    out.push(Number(o.toFixed(3)));
  }
  return out;
}

/// True when `offset` coincides (within epsilon) with one already in the list.
export function occupies(offset: number, offsets: number[]): boolean {
  return offsets.some((o) => Math.abs(o - offset) < EPS);
}

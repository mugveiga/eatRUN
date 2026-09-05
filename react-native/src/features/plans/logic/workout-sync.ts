import type { ActivityType } from '@/core/db/schema';

/// Pure math linking distance, duration and pace/speed. Distance is the
/// anchor; pace/speed and duration are the interchangeable pair.
/// pace = min/km (run); speed = km/h (bike).

export function paceOrSpeed(
  distanceKm: number,
  durationMin: number,
  activity: ActivityType,
): number {
  if (distanceKm <= 0 || durationMin <= 0) return 0;
  return activity === 'run'
    ? durationMin / distanceKm
    : distanceKm / (durationMin / 60);
}

/// Duration (min) implied by a pace/speed at a given distance.
export function durationFromPaceOrSpeed(
  distanceKm: number,
  value: number,
  activity: ActivityType,
): number {
  if (value <= 0) return 0;
  return activity === 'run' ? value * distanceKm : (distanceKm / value) * 60;
}

/// Duration (min) when distance changes but pace/speed is held constant.
export function durationScaledByDistance(
  oldDistanceKm: number,
  oldDurationMin: number,
  newDistanceKm: number,
): number {
  if (oldDistanceKm <= 0) return oldDurationMin;
  return (oldDurationMin * newDistanceKm) / oldDistanceKm;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

/// Pace as m:ss (e.g. 5.5 → "5:30").
export function formatPace(minutesPerKm: number): string {
  const totalSeconds = Math.round(minutesPerKm * 60);
  return `${Math.floor(totalSeconds / 60)}:${String(totalSeconds % 60).padStart(2, '0')}`;
}

/// Parse "m:ss" (or a plain number) into decimal minutes.
export function parsePace(text: string): number {
  if (text.includes(':')) {
    const [m, s] = text.split(':');
    return (Number(m) || 0) + (Number(s) || 0) / 60;
  }
  return Number(text) || 0;
}

/// Mask raw typed digits into m:ss (e.g. "530" → "5:30"), filling from the
/// right so the colon appears once seconds are present. Numeric keyboards
/// have no ":", so the user types digits and this inserts it.
export function maskPace(text: string): string {
  const digits = text.replace(/\D/g, '').slice(-4);
  if (digits.length <= 2) return digits;
  return `${digits.slice(0, -2)}:${digits.slice(-2)}`;
}

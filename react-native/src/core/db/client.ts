import { drizzle } from 'drizzle-orm/expo-sqlite';
import { openDatabaseSync } from 'expo-sqlite';

import * as schema from './schema';

// `enableChangeListener` is required for Drizzle's useLiveQuery reactivity.
const expo = openDatabaseSync('eatrun.db', { enableChangeListener: true });

// Enforce foreign keys (off by default in SQLite) so the plan → items cascade
// works and dangling references are rejected.
expo.execSync('PRAGMA foreign_keys = ON;');

export const db = drizzle(expo, { schema });

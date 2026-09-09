package com.eatrun.core.db

import androidx.room.ConstructedBy
import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.RoomDatabaseConstructor
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import kotlinx.coroutines.Dispatchers

@Database(entities = [FoodEntity::class], version = 1)
@ConstructedBy(AppDatabaseConstructor::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun foodDao(): FoodDao
}

/// Room's KSP processor generates the `actual` of this object for each platform
/// (Android, JVM, iOS) — the platform-specific database implementation. This
/// `expect object` is the seam; we never hand-write the actuals.
@Suppress("NO_ACTUAL_FOR_EXPECT")
expect object AppDatabaseConstructor : RoomDatabaseConstructor<AppDatabase> {
    override fun initialize(): AppDatabase
}

/// Finalize a platform-provided builder with the shared, cross-platform bits:
/// the bundled SQLite driver (same native SQLite on every target) and an IO
/// coroutine context for queries.
fun createRoomDatabase(builder: RoomDatabase.Builder<AppDatabase>): AppDatabase =
    builder
        .setDriver(BundledSQLiteDriver())
        .setQueryCoroutineContext(Dispatchers.IO)
        .build()

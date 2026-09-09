package com.eatrun.core.db

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow

/// Reactive Foods access. `observeFoods` returns a [Flow] that Room re-emits
/// whenever the table changes — the KMP analog of Drift `.watch()` / Drizzle
/// `useLiveQuery`.
@Dao
interface FoodDao {
    @Query("SELECT * FROM foods WHERE deletedAt IS NULL ORDER BY name")
    fun observeFoods(): Flow<List<FoodEntity>>

    @Upsert
    suspend fun upsert(food: FoodEntity)

    @Query("UPDATE foods SET deletedAt = :ts, updatedAt = :ts, syncStatus = 'pending' WHERE id = :id")
    suspend fun softDelete(id: String, ts: Long)
}

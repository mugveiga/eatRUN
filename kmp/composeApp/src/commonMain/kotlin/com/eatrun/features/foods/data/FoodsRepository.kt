package com.eatrun.features.foods.data

import com.eatrun.core.db.FoodDao
import com.eatrun.core.db.FoodEntity
import com.eatrun.core.db.SyncColumns
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.Clock
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/// The seam the UI talks to. Reads/writes the local DB now; a backend can slip
/// in behind it later without the UI changing (offline-first).
@OptIn(ExperimentalUuidApi::class)
class FoodsRepository(private val dao: FoodDao) {

    fun observeFoods(): Flow<List<FoodEntity>> = dao.observeFoods()

    suspend fun find(id: String): FoodEntity? = dao.findById(id)

    suspend fun softDelete(id: String) {
        dao.softDelete(id, now())
    }

    /// Create (id null) or update a food. On update we keep the existing sync
    /// row but re-stamp it pending, so a later backend re-syncs the change.
    suspend fun save(
        id: String?,
        name: String,
        carbsGrams: Int,
        sodiumMg: Int,
        caffeineMg: Int,
        notes: String,
    ) {
        val existingSync = id?.let { dao.findById(it)?.sync }
        val sync = existingSync?.copy(updatedAt = now(), syncStatus = "pending")
            ?: SyncColumns(id = Uuid.random().toString(), updatedAt = now())
        dao.upsert(
            FoodEntity(
                sync = sync,
                name = name.trim(),
                carbsGrams = carbsGrams,
                sodiumMg = sodiumMg,
                caffeineMg = caffeineMg,
                notes = notes.ifBlank { null },
            ),
        )
    }

    private fun now(): Long = Clock.System.now().toEpochMilliseconds()
}

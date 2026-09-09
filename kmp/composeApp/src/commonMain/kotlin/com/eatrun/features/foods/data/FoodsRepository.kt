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

    suspend fun softDelete(id: String) {
        dao.softDelete(id, Clock.System.now().toEpochMilliseconds())
    }

    /// Temporary — proves the reactive round-trip end to end. Replaced by the
    /// real Foods form in the next slice.
    suspend fun addSample() {
        val n = (1..99).random()
        dao.upsert(
            FoodEntity(
                sync = SyncColumns(
                    id = Uuid.random().toString(),
                    updatedAt = Clock.System.now().toEpochMilliseconds(),
                ),
                name = "Sample gel $n",
                carbsGrams = 25,
                sodiumMg = 50,
                caffeineMg = if (n % 2 == 0) 30 else 0,
            ),
        )
    }
}

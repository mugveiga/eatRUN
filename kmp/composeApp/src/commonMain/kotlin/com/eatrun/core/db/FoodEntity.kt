package com.eatrun.core.db

import androidx.room.Embedded
import androidx.room.Entity

/// A food/gel/drink. Nutrition is per single serving. The offline-first sync
/// columns come from the embedded [SyncColumns] (flattened into this table);
/// `id` is the primary key, declared by name since it's an embedded column.
@Entity(tableName = "foods", primaryKeys = ["id"])
data class FoodEntity(
    @Embedded override val sync: SyncColumns,
    val name: String,
    val photoUri: String? = null,
    val carbsGrams: Int = 0,
    val sodiumMg: Int = 0,
    val caffeineMg: Int = 0,
    val notes: String? = null,
) : Syncable

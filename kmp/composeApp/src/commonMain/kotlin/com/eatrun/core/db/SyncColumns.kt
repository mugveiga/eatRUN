package com.eatrun.core.db

/// The offline-first columns shared by every table (mirrors the Flutter
/// `SyncColumns` mixin and the RN `syncColumns` spread). `@Embedded` into an
/// entity, Room flattens these into the entity's own table — so the physical
/// columns stay flat (`id`, `updatedAt`, …) while the declaration lives once
/// here.
///
/// - id: client-generated UUID (globally unique; survives sync)
/// - updatedAt: last-write-wins conflict handling (epoch millis)
/// - deletedAt: soft delete (sync a tombstone, never a vanished row)
/// - syncStatus: "pending" until a backend confirms "synced"
/// - userId: null until login scopes data per user
data class SyncColumns(
    val id: String,
    val updatedAt: Long,
    val deletedAt: Long? = null,
    val syncStatus: String = "pending",
    val userId: String? = null,
)

/// Shared contract for any entity carrying [SyncColumns], so sync/repository
/// logic can be written once over `Syncable` rather than per entity.
interface Syncable {
    val sync: SyncColumns
}

package com.eatrun.core.storage

/// Copies picked image bytes into durable app-owned storage and returns an
/// absolute path to display later. Picker URIs (esp. Android content URIs) can
/// lose access after restart, so we own a copy. Platform impls live in
/// androidMain/jvmMain (iOS later) and are bound in the Koin platform module.
interface ImageStore {
    suspend fun save(id: String, bytes: ByteArray): String
}

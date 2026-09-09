package com.eatrun.core.storage

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/// Stores images under ~/.eatrun/images.
class DesktopImageStore : ImageStore {
    private val dir = File(System.getProperty("user.home"), ".eatrun/images").apply { mkdirs() }

    override suspend fun save(id: String, bytes: ByteArray): String =
        withContext(Dispatchers.IO) {
            val file = File(dir, "$id.img")
            file.writeBytes(bytes)
            file.absolutePath
        }
}

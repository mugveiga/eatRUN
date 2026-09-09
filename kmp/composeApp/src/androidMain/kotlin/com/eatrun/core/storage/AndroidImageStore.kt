package com.eatrun.core.storage

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/// Stores images under the app's private files dir.
class AndroidImageStore(context: Context) : ImageStore {
    private val dir = File(context.filesDir, "images").apply { mkdirs() }

    override suspend fun save(id: String, bytes: ByteArray): String =
        withContext(Dispatchers.IO) {
            val file = File(dir, "$id.img")
            file.writeBytes(bytes)
            file.absolutePath
        }
}

package com.eatrun.core.di

import androidx.room.Room
import androidx.room.RoomDatabase
import com.eatrun.core.db.AppDatabase
import org.koin.core.module.Module
import org.koin.dsl.module
import java.io.File

/// Desktop builds the Room database against a file in the user's home dir
/// (~/.eatrun/eatrun.db) — no Android Context involved.
actual fun platformModule(): Module = module {
    single<RoomDatabase.Builder<AppDatabase>> {
        val dir = File(System.getProperty("user.home"), ".eatrun").apply { mkdirs() }
        val dbFile = File(dir, "eatrun.db")
        Room.databaseBuilder<AppDatabase>(name = dbFile.absolutePath)
    }
}

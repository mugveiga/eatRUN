package com.eatrun.core.di

import androidx.room.Room
import androidx.room.RoomDatabase
import com.eatrun.core.db.AppDatabase
import org.koin.android.ext.koin.androidContext
import org.koin.core.module.Module
import org.koin.dsl.module

/// Android builds the Room database against an app `Context` and the app's
/// private database path.
actual fun platformModule(): Module = module {
    single<RoomDatabase.Builder<AppDatabase>> {
        val context = androidContext()
        val dbFile = context.getDatabasePath("eatrun.db")
        Room.databaseBuilder<AppDatabase>(
            context = context.applicationContext,
            name = dbFile.absolutePath,
        )
    }
}

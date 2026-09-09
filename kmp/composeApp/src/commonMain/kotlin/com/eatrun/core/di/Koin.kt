package com.eatrun.core.di

import com.eatrun.core.db.AppDatabase
import com.eatrun.core.db.createRoomDatabase
import com.eatrun.features.foods.data.FoodsRepository
import org.koin.core.module.Module
import org.koin.dsl.KoinAppDeclaration
import org.koin.core.context.startKoin
import org.koin.dsl.module

/// Platform-specific DI — the `expect`/`actual` seam. Each platform supplies a
/// `RoomDatabase.Builder<AppDatabase>` its own way: Android needs a `Context`,
/// Desktop uses a file path. Everything downstream is shared.
expect fun platformModule(): Module

/// Shared graph: builder → database → dao → repository. Consumes whatever
/// builder the platform module provided.
fun sharedModule(): Module = module {
    single { createRoomDatabase(get()) }
    single { get<AppDatabase>().foodDao() }
    single { FoodsRepository(get()) }
}

/// Called once per platform entry point (Desktop `main`, Android `Application`).
fun initKoin(appDeclaration: KoinAppDeclaration = {}) = startKoin {
    appDeclaration()
    modules(platformModule(), sharedModule())
}

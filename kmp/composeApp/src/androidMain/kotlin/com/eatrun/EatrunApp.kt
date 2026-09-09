package com.eatrun

import android.app.Application
import com.eatrun.core.di.initKoin
import org.koin.android.ext.koin.androidContext

/// Android entry point for process startup. Starts Koin, giving the platform
/// module the app `Context` it needs to build Room.
class EatrunApp : Application() {
    override fun onCreate() {
        super.onCreate()
        initKoin {
            androidContext(this@EatrunApp)
        }
    }
}

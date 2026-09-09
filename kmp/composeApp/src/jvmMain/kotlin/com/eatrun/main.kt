package com.eatrun

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import com.eatrun.core.di.initKoin

/// Desktop (JVM) entry point. Starts Koin once, then hosts the shared [App].
fun main() {
    initKoin()
    application {
        Window(onCloseRequest = ::exitApplication, title = "eatRUN") {
            App()
        }
    }
}

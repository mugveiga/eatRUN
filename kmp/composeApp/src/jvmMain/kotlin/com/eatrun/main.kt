package com.eatrun

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application

/// Desktop (JVM) entry point. The Android and iOS entry points will call the
/// same [App] composable from their own platform source sets.
fun main() = application {
    Window(onCloseRequest = ::exitApplication, title = "eatRUN") {
        App()
    }
}

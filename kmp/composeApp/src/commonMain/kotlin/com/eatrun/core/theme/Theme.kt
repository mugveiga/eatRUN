package com.eatrun.core.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

private val Orange = Color(0xFFFF5722)
private val OrangeLight = Color(0xFFFF7043)

/// Deep-orange seed shared with the Flutter/RN builds. Light and dark schemes;
/// Material 3 fills the rest of the roles from these seeds.
val LightColors = lightColorScheme(
    primary = Orange,
    secondary = Orange,
)

val DarkColors = darkColorScheme(
    primary = OrangeLight,
    secondary = OrangeLight,
)

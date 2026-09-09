package com.eatrun

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.eatrun.features.foods.ui.FoodsListScreen
import org.koin.compose.KoinContext

private val EatrunOrange = Color(0xFFFF5722)

/// Root of the shared Compose UI — runs on Desktop, Android and iOS. Koin is
/// started by each platform entry point; [KoinContext] exposes it to the tree.
@Composable
fun App() {
    KoinContext {
        MaterialTheme(colorScheme = lightColorScheme(primary = EatrunOrange)) {
            Surface {
                FoodsListScreen()
            }
        }
    }
}

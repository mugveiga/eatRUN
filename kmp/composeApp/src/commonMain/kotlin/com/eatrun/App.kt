package com.eatrun

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.eatrun.core.theme.DarkColors
import com.eatrun.core.theme.LightColors
import com.eatrun.features.foods.ui.FoodFormRoute
import com.eatrun.features.foods.ui.FoodsListRoute
import kotlinx.serialization.Serializable
import org.koin.compose.KoinContext

/// Type-safe navigation routes (kotlinx.serialization) instead of string paths.
/// Not `private`: serialization reads the object's INSTANCE field reflectively,
/// which fails on a package-private (top-level `private`) type.
@Serializable
internal object FoodsList

@Serializable
internal data class FoodForm(val foodId: String? = null)

/// Root of the shared Compose UI — runs on Desktop, Android and iOS. Koin is
/// started by each platform entry point; [KoinContext] exposes it to the tree.
@Composable
fun App() {
    KoinContext {
        MaterialTheme(colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors) {
            Surface {
                val nav = rememberNavController()
                NavHost(navController = nav, startDestination = FoodsList) {
                    composable<FoodsList> {
                        FoodsListRoute(
                            onAdd = { nav.navigate(FoodForm()) },
                            onEdit = { id -> nav.navigate(FoodForm(foodId = id)) },
                        )
                    }
                    composable<FoodForm> { entry ->
                        FoodFormRoute(
                            foodId = entry.toRoute<FoodForm>().foodId,
                            onDone = { nav.popBackStack() },
                        )
                    }
                }
            }
        }
    }
}

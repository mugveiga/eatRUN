package com.eatrun

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.eatrun.core.theme.DarkColors
import com.eatrun.core.theme.LightColors
import com.eatrun.features.foods.ui.FoodFormScreen
import com.eatrun.features.foods.ui.FoodsListScreen
import org.koin.compose.KoinContext

private object Routes {
    const val FOODS = "foods"
    const val FOOD_FORM = "food_form?foodId={foodId}"
    fun foodForm(id: String? = null) = if (id == null) "food_form" else "food_form?foodId=$id"
}

/// Root of the shared Compose UI — runs on Desktop, Android and iOS. Koin is
/// started by each platform entry point; [KoinContext] exposes it to the tree.
/// Navigation Compose drives list ↔ form.
@Composable
fun App() {
    KoinContext {
        MaterialTheme(colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors) {
            Surface {
                val nav = rememberNavController()
                NavHost(navController = nav, startDestination = Routes.FOODS) {
                    composable(Routes.FOODS) {
                        FoodsListScreen(
                            onAdd = { nav.navigate(Routes.foodForm()) },
                            onEdit = { id -> nav.navigate(Routes.foodForm(id)) },
                        )
                    }
                    composable(
                        route = Routes.FOOD_FORM,
                        arguments = listOf(
                            navArgument("foodId") {
                                type = NavType.StringType
                                nullable = true
                                defaultValue = null
                            },
                        ),
                    ) { entry ->
                        FoodFormScreen(
                            foodId = entry.arguments?.getString("foodId"),
                            onDone = { nav.popBackStack() },
                        )
                    }
                }
            }
        }
    }
}

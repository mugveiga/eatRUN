package com.eatrun.features.foods.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.eatrun.core.db.FoodEntity
import com.eatrun.features.foods.data.FoodsRepository
import com.eatrun.resources.Res
import com.eatrun.resources.action_add_food
import com.eatrun.resources.foods_empty
import com.eatrun.resources.foods_title
import com.eatrun.resources.nutrition_summary
import org.jetbrains.compose.resources.stringResource
import org.koin.compose.koinInject

/// Route: holds the ViewModel + DI wiring and passes immutable state down and
/// events up to the stateless [FoodsListScreen].
@Composable
fun FoodsListRoute(onAdd: () -> Unit, onEdit: (String) -> Unit) {
    val repository: FoodsRepository = koinInject()
    val vm: FoodsListViewModel = viewModel { FoodsListViewModel(repository) }
    val foods by vm.foods.collectAsState()
    FoodsListScreen(
        foods = foods,
        onAdd = onAdd,
        onEdit = onEdit,
    )
}

/// Stateless: a pure function of [foods] plus event callbacks. No DI, no VM.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FoodsListScreen(
    foods: List<FoodEntity>,
    onAdd: () -> Unit,
    onEdit: (String) -> Unit,
) {
    Scaffold(
        topBar = { TopAppBar(title = { Text(stringResource(Res.string.foods_title)) }) },
        floatingActionButton = {
            FloatingActionButton(onClick = onAdd) {
                Icon(Icons.Filled.Add, contentDescription = stringResource(Res.string.action_add_food))
            }
        },
    ) { padding ->
        if (foods.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center,
            ) {
                Text(stringResource(Res.string.foods_empty))
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize().padding(padding)) {
                items(foods, key = { it.sync.id }) { food ->
                    ListItem(
                        modifier = Modifier.clickable { onEdit(food.sync.id) },
                        leadingContent = {
                            FoodImage(path = food.photoUri, modifier = Modifier.size(48.dp))
                        },
                        headlineContent = { Text(food.name) },
                        supportingContent = {
                            Text(
                                stringResource(
                                    Res.string.nutrition_summary,
                                    food.carbsGrams,
                                    food.sodiumMg,
                                    food.caffeineMg,
                                ),
                            )
                        },
                    )
                    HorizontalDivider()
                }
            }
        }
    }
}

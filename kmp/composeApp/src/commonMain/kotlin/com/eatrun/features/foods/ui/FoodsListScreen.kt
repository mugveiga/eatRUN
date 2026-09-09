package com.eatrun.features.foods.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.eatrun.features.foods.data.FoodsRepository
import kotlinx.coroutines.launch
import org.koin.compose.koinInject

/// Reactive Foods list bound to the DAO's Flow. The FAB adds a sample food to
/// demonstrate the round-trip: write → Room emits → list recomposes.
@Composable
fun FoodsListScreen(repository: FoodsRepository = koinInject()) {
    val foods by repository.observeFoods().collectAsState(initial = emptyList())
    val scope = rememberCoroutineScope()

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = { scope.launch { repository.addSample() } }) {
                Icon(Icons.Filled.Add, contentDescription = "Add sample food")
            }
        },
    ) { padding ->
        if (foods.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center,
            ) {
                Text("No foods yet — tap + to add a sample")
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize().padding(padding)) {
                items(foods, key = { it.sync.id }) { food ->
                    ListItem(
                        headlineContent = { Text(food.name) },
                        supportingContent = {
                            Text(
                                "${food.carbsGrams}g carbs · " +
                                    "${food.sodiumMg}mg sodium · " +
                                    "${food.caffeineMg}mg caffeine",
                            )
                        },
                        trailingContent = {
                            IconButton(onClick = { scope.launch { repository.softDelete(food.sync.id) } }) {
                                Icon(Icons.Filled.Delete, contentDescription = "Delete")
                            }
                        },
                    )
                    HorizontalDivider()
                }
            }
        }
    }
}

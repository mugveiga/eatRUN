package com.eatrun.features.foods.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.LaunchedEffect
import androidx.lifecycle.viewmodel.compose.viewModel
import com.eatrun.features.foods.data.FoodsRepository
import org.koin.compose.koinInject

/// Create/edit a food. The repository is injected by Koin; the ViewModel is
/// created (and scoped) by lifecycle's `viewModel { }` with the repo + id.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FoodFormScreen(foodId: String?, onDone: () -> Unit) {
    val repository: FoodsRepository = koinInject()
    val vm: FoodFormViewModel = viewModel(key = foodId ?: "new") {
        FoodFormViewModel(repository, foodId)
    }
    val state by vm.state.collectAsState()

    LaunchedEffect(state.done) {
        if (state.done) onDone()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (foodId == null) "New food" else "Edit food") },
                navigationIcon = {
                    IconButton(onClick = onDone) {
                        Icon(Icons.Filled.Close, contentDescription = "Cancel")
                    }
                },
                actions = {
                    if (foodId != null) {
                        IconButton(onClick = vm::delete) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete")
                        }
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedTextField(
                value = state.name,
                onValueChange = vm::onName,
                label = { Text("Name") },
                isError = state.nameError,
                supportingText = if (state.nameError) {
                    { Text("Required", color = MaterialTheme.colorScheme.error) }
                } else null,
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                NumberField(
                    label = "Carbs",
                    value = state.carbs,
                    onChange = vm::onCarbs,
                    unit = "g",
                    max = FoodFormViewModel.MAX_CARBS,
                    modifier = Modifier.weight(1f),
                )
                NumberField(
                    label = "Sodium",
                    value = state.sodium,
                    onChange = vm::onSodium,
                    unit = "mg",
                    max = FoodFormViewModel.MAX_SODIUM,
                    modifier = Modifier.weight(1f),
                )
                NumberField(
                    label = "Caffeine",
                    value = state.caffeine,
                    onChange = vm::onCaffeine,
                    unit = "mg",
                    max = FoodFormViewModel.MAX_CAFFEINE,
                    modifier = Modifier.weight(1f),
                )
            }
            OutlinedTextField(
                value = state.notes,
                onValueChange = vm::onNotes,
                label = { Text("Notes") },
                modifier = Modifier.fillMaxWidth().height(120.dp),
            )
            Button(onClick = vm::save, modifier = Modifier.fillMaxWidth()) {
                Text("Save")
            }
        }
    }
}

@Composable
private fun NumberField(
    label: String,
    value: String,
    onChange: (String) -> Unit,
    unit: String,
    max: Int,
    modifier: Modifier,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        suffix = { Text(unit) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        // A supporting line on every field keeps the three the same height.
        supportingText = { Text("max $max") },
        modifier = modifier,
    )
}

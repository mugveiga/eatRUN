package com.eatrun.features.foods.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.eatrun.core.storage.ImageStore
import com.eatrun.features.foods.data.FoodsRepository
import com.eatrun.resources.Res
import com.eatrun.resources.action_add_photo
import com.eatrun.resources.action_cancel
import com.eatrun.resources.action_change_photo
import com.eatrun.resources.action_delete
import com.eatrun.resources.action_enter_as_salt
import com.eatrun.resources.action_enter_as_sodium
import com.eatrun.resources.action_save
import com.eatrun.resources.field_caffeine
import com.eatrun.resources.field_carbs
import com.eatrun.resources.field_name
import com.eatrun.resources.field_notes
import com.eatrun.resources.field_required
import com.eatrun.resources.field_salt
import com.eatrun.resources.field_sodium
import com.eatrun.resources.food_edit_title
import com.eatrun.resources.food_new_title
import com.eatrun.resources.unit_g
import com.eatrun.resources.unit_mg
import io.github.vinceglb.filekit.compose.rememberFilePickerLauncher
import org.jetbrains.compose.resources.stringResource
import io.github.vinceglb.filekit.core.PickerMode
import io.github.vinceglb.filekit.core.PickerType
import kotlinx.coroutines.launch
import org.koin.compose.koinInject
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/// Route: owns the ViewModel + DI + the image-picker side effect, and hands the
/// stateless [FoodFormScreen] an immutable state plus event callbacks.
@OptIn(ExperimentalUuidApi::class)
@Composable
fun FoodFormRoute(foodId: String?, onDone: () -> Unit) {
    val repository: FoodsRepository = koinInject()
    val imageStore: ImageStore = koinInject()
    val vm: FoodFormViewModel = viewModel(key = foodId ?: "new") {
        FoodFormViewModel(repository, foodId)
    }
    val state by vm.state.collectAsState()
    val scope = rememberCoroutineScope()

    LaunchedEffect(state.done) {
        if (state.done) onDone()
    }

    // Pick an image, copy its bytes into app storage, then keep the stable path.
    val picker = rememberFilePickerLauncher(
        type = PickerType.Image,
        mode = PickerMode.Single,
    ) { file ->
        if (file != null) {
            scope.launch {
                val path = imageStore.save(Uuid.random().toString(), file.readBytes())
                vm.onPhoto(path)
            }
        }
    }

    FoodFormScreen(
        state = state,
        isEditing = foodId != null,
        onName = vm::onName,
        onCarbs = vm::onCarbs,
        onSodium = vm::onSodium,
        onToggleSalt = vm::toggleSalt,
        onCaffeine = vm::onCaffeine,
        onNotes = vm::onNotes,
        onPickPhoto = { picker.launch() },
        onSave = vm::save,
        onDelete = vm::delete,
        onBack = onDone,
    )
}

/// Stateless: pure function of [state] with events out. No DI, no VM, no I/O.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FoodFormScreen(
    state: FoodFormState,
    isEditing: Boolean,
    onName: (String) -> Unit,
    onCarbs: (String) -> Unit,
    onSodium: (String) -> Unit,
    onToggleSalt: () -> Unit,
    onCaffeine: (String) -> Unit,
    onNotes: (String) -> Unit,
    onPickPhoto: () -> Unit,
    onSave: () -> Unit,
    onDelete: () -> Unit,
    onBack: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(stringResource(if (isEditing) Res.string.food_edit_title else Res.string.food_new_title))
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.Close, contentDescription = stringResource(Res.string.action_cancel))
                    }
                },
                actions = {
                    if (isEditing) {
                        IconButton(onClick = onDelete) {
                            Icon(Icons.Filled.Delete, contentDescription = stringResource(Res.string.action_delete))
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
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                FoodImage(path = state.photoUri, modifier = Modifier.size(120.dp))
                TextButton(onClick = onPickPhoto) {
                    Text(
                        stringResource(
                            if (state.photoUri == null) Res.string.action_add_photo
                            else Res.string.action_change_photo,
                        ),
                    )
                }
            }

            OutlinedTextField(
                value = state.name,
                onValueChange = onName,
                label = { Text(stringResource(Res.string.field_name)) },
                isError = state.nameError,
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            if (state.nameError) {
                Text(
                    text = stringResource(Res.string.field_required),
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                NumberField(
                    stringResource(Res.string.field_carbs), state.carbs, onCarbs,
                    stringResource(Res.string.unit_g), Modifier.weight(1f),
                )
                NumberField(
                    label = stringResource(if (state.saltMode) Res.string.field_salt else Res.string.field_sodium),
                    value = state.sodium,
                    onChange = onSodium,
                    unit = stringResource(if (state.saltMode) Res.string.unit_g else Res.string.unit_mg),
                    modifier = Modifier.weight(1f),
                    decimal = state.saltMode,
                )
                NumberField(
                    stringResource(Res.string.field_caffeine), state.caffeine, onCaffeine,
                    stringResource(Res.string.unit_mg), Modifier.weight(1f),
                )
            }
            TextButton(onClick = onToggleSalt) {
                Text(
                    stringResource(
                        if (state.saltMode) Res.string.action_enter_as_sodium
                        else Res.string.action_enter_as_salt,
                    ),
                )
            }

            OutlinedTextField(
                value = state.notes,
                onValueChange = onNotes,
                label = { Text(stringResource(Res.string.field_notes)) },
                modifier = Modifier.fillMaxWidth().height(120.dp),
            )
            Button(onClick = onSave, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(Res.string.action_save))
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
    modifier: Modifier,
    decimal: Boolean = false,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        suffix = { Text(unit) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(
            keyboardType = if (decimal) KeyboardType.Decimal else KeyboardType.Number,
        ),
        modifier = modifier,
    )
}

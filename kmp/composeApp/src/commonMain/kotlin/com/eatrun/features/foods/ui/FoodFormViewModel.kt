package com.eatrun.features.foods.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eatrun.features.foods.data.FoodsRepository
import com.eatrun.features.foods.logic.MAX_SALT_G
import com.eatrun.features.foods.logic.MAX_SODIUM_MG
import com.eatrun.features.foods.logic.formatSalt
import com.eatrun.features.foods.logic.saltToSodiumMg
import com.eatrun.features.foods.logic.sodiumMgToSalt
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/// Form state. Numeric fields are Strings (what the text inputs hold); the
/// repository parses them on save.
data class FoodFormState(
    val name: String = "",
    val carbs: String = "",
    // Holds sodium mg when [saltMode] is false, else salt grams (may be decimal).
    val sodium: String = "",
    val saltMode: Boolean = false,
    val caffeine: String = "",
    val notes: String = "",
    val photoUri: String? = null,
    val nameError: Boolean = false,
    val loading: Boolean = false,
    val done: Boolean = false,
)

/// Shared ViewModel — this exact class runs on Desktop, Android and iOS
/// (`androidx.lifecycle.ViewModel` is multiplatform). Holds form state as a
/// [StateFlow], validates, and saves through the repository. Later, the iOS
/// food form will drive *this same* ViewModel from SwiftUI.
class FoodFormViewModel(
    private val repository: FoodsRepository,
    private val foodId: String?,
) : ViewModel() {

    companion object {
        const val MAX_CARBS = 300
        const val MAX_CAFFEINE = 1000
    }

    private val _state = MutableStateFlow(FoodFormState(loading = foodId != null))
    val state: StateFlow<FoodFormState> = _state.asStateFlow()

    init {
        if (foodId != null) {
            viewModelScope.launch {
                val food = repository.find(foodId)
                _state.update {
                    if (food == null) {
                        it.copy(loading = false)
                    } else {
                        it.copy(
                            name = food.name,
                            carbs = food.carbsGrams.toString(),
                            sodium = food.sodiumMg.toString(),
                            caffeine = food.caffeineMg.toString(),
                            notes = food.notes ?: "",
                            photoUri = food.photoUri,
                            loading = false,
                        )
                    }
                }
            }
        }
    }

    fun onName(v: String) = _state.update { it.copy(name = v, nameError = false) }
    fun onCarbs(v: String) = _state.update { it.copy(carbs = capDigits(v, MAX_CARBS)) }
    fun onCaffeine(v: String) = _state.update { it.copy(caffeine = capDigits(v, MAX_CAFFEINE)) }
    fun onNotes(v: String) = _state.update { it.copy(notes = v) }
    fun onPhoto(path: String) = _state.update { it.copy(photoUri = path) }

    /// Sodium field: digits (mg) or a decimal (salt g) depending on mode,
    /// clamped to each unit's max.
    fun onSodium(v: String) = _state.update {
        if (it.saltMode) {
            val cleaned = cleanDecimal(v)
            val d = cleaned.toDoubleOrNull()
            it.copy(sodium = if (d != null && d > MAX_SALT_G) formatSalt(MAX_SALT_G) else cleaned)
        } else {
            val digits = v.filter(Char::isDigit)
            val n = digits.toIntOrNull()
            it.copy(sodium = if (n != null && n > MAX_SODIUM_MG) MAX_SODIUM_MG.toString() else digits)
        }
    }

    /// Flip between mg and salt-g input, converting the current value so the
    /// stored sodium never changes on toggle.
    fun toggleSalt() = _state.update {
        val next = !it.saltMode
        val converted = if (next) {
            formatSalt(sodiumMgToSalt(it.sodium.toIntOrNull() ?: 0))
        } else {
            saltToSodiumMg(it.sodium.toDoubleOrNull() ?: 0.0).toString()
        }
        it.copy(saltMode = next, sodium = converted)
    }

    /// Keep only digits, then clamp to the field's max (empty stays empty).
    private fun capDigits(v: String, max: Int): String {
        val n = v.filter(Char::isDigit).toIntOrNull() ?: return ""
        return minOf(n, max).toString()
    }

    /// Digits with at most one decimal point.
    private fun cleanDecimal(v: String): String {
        val filtered = v.filter { it.isDigit() || it == '.' }
        val dot = filtered.indexOf('.')
        return if (dot == -1) filtered
        else filtered.substring(0, dot + 1) + filtered.substring(dot + 1).replace(".", "")
    }

    fun delete() {
        val id = foodId ?: return
        viewModelScope.launch {
            repository.softDelete(id)
            _state.update { it.copy(done = true) }
        }
    }

    fun save() {
        val s = _state.value
        if (s.name.isBlank()) {
            _state.update { it.copy(nameError = true) }
            return
        }
        val sodiumMg = if (s.saltMode) {
            saltToSodiumMg(s.sodium.toDoubleOrNull() ?: 0.0)
        } else {
            s.sodium.toIntOrNull() ?: 0
        }
        viewModelScope.launch {
            repository.save(
                id = foodId,
                name = s.name,
                carbsGrams = s.carbs.toIntOrNull() ?: 0,
                sodiumMg = minOf(sodiumMg, MAX_SODIUM_MG),
                caffeineMg = s.caffeine.toIntOrNull() ?: 0,
                notes = s.notes,
                photoUri = s.photoUri,
            )
            _state.update { it.copy(done = true) }
        }
    }
}

package com.eatrun.features.foods.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eatrun.features.foods.data.FoodsRepository
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
    val sodium: String = "",
    val caffeine: String = "",
    val notes: String = "",
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
        const val MAX_SODIUM = 10000
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
                            loading = false,
                        )
                    }
                }
            }
        }
    }

    fun onName(v: String) = _state.update { it.copy(name = v, nameError = false) }
    fun onCarbs(v: String) = _state.update { it.copy(carbs = capDigits(v, MAX_CARBS)) }
    fun onSodium(v: String) = _state.update { it.copy(sodium = capDigits(v, MAX_SODIUM)) }
    fun onCaffeine(v: String) = _state.update { it.copy(caffeine = capDigits(v, MAX_CAFFEINE)) }
    fun onNotes(v: String) = _state.update { it.copy(notes = v) }

    /// Keep only digits, then clamp to the field's max (empty stays empty).
    private fun capDigits(v: String, max: Int): String {
        val n = v.filter(Char::isDigit).toIntOrNull() ?: return ""
        return minOf(n, max).toString()
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
        viewModelScope.launch {
            repository.save(
                id = foodId,
                name = s.name,
                carbsGrams = s.carbs.toIntOrNull() ?: 0,
                sodiumMg = s.sodium.toIntOrNull() ?: 0,
                caffeineMg = s.caffeine.toIntOrNull() ?: 0,
                notes = s.notes,
            )
            _state.update { it.copy(done = true) }
        }
    }
}

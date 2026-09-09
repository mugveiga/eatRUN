package com.eatrun.features.foods.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.eatrun.core.db.FoodEntity
import com.eatrun.features.foods.data.FoodsRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

/// Exposes the reactive Foods list as immutable state (state down). The Room
/// `Flow` is turned into a `StateFlow` scoped to the ViewModel so the screen
/// just observes. Deletion lives in the edit screen, not here.
class FoodsListViewModel(private val repository: FoodsRepository) : ViewModel() {

    val foods: StateFlow<List<FoodEntity>> = repository.observeFoods()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
}

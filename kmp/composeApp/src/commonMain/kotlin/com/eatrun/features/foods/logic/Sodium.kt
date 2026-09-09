package com.eatrun.features.foods.logic

import kotlin.math.roundToInt

/// Salt (g) ⇄ sodium (mg). Table salt is ~40% sodium by mass, so 1 g of salt
/// ≈ 400 mg sodium. Storage is always sodium mg; the form lets you enter
/// either and converts. Pure + unit-testable (mirrors the Flutter/RN builds).
const val SODIUM_PER_SALT_G = 400.0
const val MAX_SODIUM_MG = 10_000
const val MAX_SALT_G = 25.0

fun saltToSodiumMg(saltG: Double): Int = (saltG * SODIUM_PER_SALT_G).roundToInt()

fun sodiumMgToSalt(sodiumMg: Int): Double = sodiumMg / SODIUM_PER_SALT_G

/// Trim a salt value for display: whole numbers show as ints, otherwise up to
/// two decimals with no trailing zeros (400 mg → "1", 500 mg → "1.25").
fun formatSalt(saltG: Double): String {
    if (saltG % 1.0 == 0.0) return saltG.toInt().toString()
    val twoDp = (saltG * 100).roundToInt() / 100.0
    return twoDp.toString().trimEnd('0').trimEnd('.')
}

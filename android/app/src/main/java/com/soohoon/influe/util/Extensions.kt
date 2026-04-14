package com.soohoon.influe.util

import java.text.NumberFormat
import java.util.Locale

fun Double.krwFormatted(): String {
    val formatter = NumberFormat.getNumberInstance(Locale.KOREA)
    return "${formatter.format(this.toLong())}원"
}

fun formatCurrency(text: String): String {
    val digits = text.filter { it.isDigit() }
    if (digits.isEmpty()) return ""
    val number = digits.toLongOrNull() ?: return ""
    if (number <= 0) return ""
    val formatter = NumberFormat.getNumberInstance(Locale.KOREA)
    return "${formatter.format(number)}원"
}

fun parseCurrencyToDouble(text: String): Double {
    return text.filter { it.isDigit() }.toDoubleOrNull() ?: 0.0
}

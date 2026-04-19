package com.soohoon.influe.ui.theme

import android.content.Context
import androidx.compose.runtime.*
import androidx.compose.ui.graphics.Color
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.themeDataStore by preferencesDataStore(name = "theme_prefs")

enum class AppThemeType(val displayName: String) {
    LAVENDER("라벤더"),
    ROSE("로즈"),
    OCEAN("오션"),
    MINT("민트"),
    SUNSET("선셋"),
    MIDNIGHT("미드나잇"),
    PASTEL("파스텔"),
    CLEAN("클린")
}

data class AppTheme(
    val type: AppThemeType,
    val primary: Color,
    val secondary: Color,
    val accent: Color,
    val background: Color,
    val surfaceBackground: Color,
    val cardBackground: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val gradient: List<Color>,
    val success: Color = Color(0xFF34C759),
    val warning: Color = Color(0xFFFF9500),
    val danger: Color = Color(0xFFFF3B30),
    val divider: Color,
    val isDark: Boolean = false
)

fun getTheme(type: AppThemeType): AppTheme {
    val lightBg = Color(0xFFF8F9FA)
    val lightSurface = Color(0xFFF0F1F3)
    val lightCard = Color(0xFFFFFFFF)
    val lightText = Color(0xFF1A1A1A)
    val lightTextSec = Color(0xFF6B7280)
    val lightDivider = Color(0xFFE5E7EB)

    return when (type) {
        AppThemeType.LAVENDER -> AppTheme(
            type = type,
            primary = Color(0xFF7C3AED),
            secondary = Color(0xFFA78BFA),
            accent = Color(0xFFEC4899),
            background = Color(0xFFF5F3FF),
            surfaceBackground = Color(0xFFEDE9FE),
            cardBackground = lightCard,
            textPrimary = lightText,
            textSecondary = lightTextSec,
            gradient = listOf(Color(0xFF7C3AED), Color(0xFFC4B5FD)),
            divider = lightDivider
        )
        AppThemeType.ROSE -> AppTheme(
            type = type, primary = Color(0xFFE91E63), secondary = Color(0xFFF48FB1),
            accent = Color(0xFFFF4081), background = lightBg, surfaceBackground = lightSurface,
            cardBackground = lightCard, textPrimary = lightText, textSecondary = lightTextSec,
            gradient = listOf(Color(0xFFE91E63), Color(0xFFF48FB1)), divider = lightDivider
        )
        AppThemeType.OCEAN -> AppTheme(
            type = type, primary = Color(0xFF0288D1), secondary = Color(0xFF4FC3F7),
            accent = Color(0xFF03A9F4), background = lightBg, surfaceBackground = lightSurface,
            cardBackground = lightCard, textPrimary = lightText, textSecondary = lightTextSec,
            gradient = listOf(Color(0xFF0288D1), Color(0xFF4FC3F7)), divider = lightDivider
        )
        AppThemeType.MINT -> AppTheme(
            type = type, primary = Color(0xFF00BFA5), secondary = Color(0xFF80CBC4),
            accent = Color(0xFF26A69A), background = lightBg, surfaceBackground = lightSurface,
            cardBackground = lightCard, textPrimary = lightText, textSecondary = lightTextSec,
            gradient = listOf(Color(0xFF00BFA5), Color(0xFF80CBC4)), divider = lightDivider
        )
        AppThemeType.SUNSET -> AppTheme(
            type = type, primary = Color(0xFFFF6D00), secondary = Color(0xFFFFAB40),
            accent = Color(0xFFFF9100), background = lightBg, surfaceBackground = lightSurface,
            cardBackground = lightCard, textPrimary = lightText, textSecondary = lightTextSec,
            gradient = listOf(Color(0xFFFF6D00), Color(0xFFFFAB40)), divider = lightDivider
        )
        AppThemeType.MIDNIGHT -> AppTheme(
            type = type, primary = Color(0xFF5C6BC0), secondary = Color(0xFF7986CB),
            accent = Color(0xFF7C4DFF), background = Color(0xFF121212), surfaceBackground = Color(0xFF1E1E1E),
            cardBackground = Color(0xFF2C2C2C), textPrimary = Color(0xFFF5F5F5), textSecondary = Color(0xFF9CA3AF),
            gradient = listOf(Color(0xFF5C6BC0), Color(0xFF7986CB)), divider = Color(0xFF333333), isDark = true
        )
        AppThemeType.PASTEL -> AppTheme(
            type = type,
            primary = Color(0xFF8B5CF6),
            secondary = Color(0xFFEC4899),
            accent = Color(0xFF06B6D4),
            background = Color(0xFFF8F7FE),
            surfaceBackground = Color(0xFFF0EEFF),
            cardBackground = Color(0xFFFFFFFF),
            textPrimary = Color(0xFF1E1B4B),
            textSecondary = Color(0xFF8B83A3),
            gradient = listOf(Color(0xFFC4B5FD), Color(0xFFF9A8D4)),
            success = Color(0xFF10B981),
            warning = Color(0xFFF59E0B),
            danger = Color(0xFFF43F5E),
            divider = Color(0xFFEDE9FE)
        )
        AppThemeType.CLEAN -> AppTheme(
            type = type, primary = Color(0xFF0095F6), secondary = Color(0xFFDD2A7B),
            accent = Color(0xFFF58529), background = lightBg, surfaceBackground = lightSurface,
            cardBackground = lightCard, textPrimary = lightText, textSecondary = lightTextSec,
            gradient = listOf(Color(0xFF0095F6), Color(0xFFDD2A7B), Color(0xFFF58529)), divider = lightDivider
        )
    }
}

class ThemeManager(private val context: Context) {
    private val _currentTheme = mutableStateOf(getTheme(AppThemeType.PASTEL))
    val theme: State<AppTheme> = _currentTheme

    suspend fun loadTheme() {
        val prefs = context.themeDataStore.data.first()
        val typeName = prefs[stringPreferencesKey("theme_type")] ?: AppThemeType.PASTEL.name
        val type = try { AppThemeType.valueOf(typeName) } catch (_: Exception) { AppThemeType.PASTEL }
        _currentTheme.value = getTheme(type)
    }

    suspend fun setTheme(type: AppThemeType) {
        _currentTheme.value = getTheme(type)
        context.themeDataStore.edit { prefs ->
            prefs[stringPreferencesKey("theme_type")] = type.name
        }
    }
}

val LocalAppTheme = staticCompositionLocalOf { getTheme(AppThemeType.PASTEL) }

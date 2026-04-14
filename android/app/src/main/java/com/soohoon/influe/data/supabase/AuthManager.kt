package com.soohoon.influe.data.supabase

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.soohoon.influe.data.model.ProfileDTO
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.handleDeeplinks
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "auth_prefs")

class AuthManager(private val context: Context) {
    private val supabase = SupabaseClient.client

    private val _currentProfile = MutableStateFlow<ProfileDTO?>(null)
    val currentProfile: StateFlow<ProfileDTO?> = _currentProfile.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    val currentUserId: String?
        get() = supabase.auth.currentUserOrNull()?.id

    suspend fun checkSession() {
        _isLoading.value = true
        try {
            val status = supabase.auth.sessionStatus.first()
            when (status) {
                is SessionStatus.Authenticated -> {
                    _isAuthenticated.value = true
                    fetchProfile()
                }
                is SessionStatus.NotAuthenticated -> {
                    _isAuthenticated.value = false
                    _currentProfile.value = null
                }
                else -> {}
            }
        } catch (e: Exception) {
            _isAuthenticated.value = false
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun signInWithGoogle() {
        try {
            _isLoading.value = true
            supabase.auth.signInWith(Google)
        } catch (e: Exception) {
            _errorMessage.value = "Google 로그인에 실패했습니다: ${e.localizedMessage}"
            _isLoading.value = false
        }
    }

    suspend fun handleAuthCallback(url: String) {
        try {
            supabase.handleDeeplinks(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url)))
            _isAuthenticated.value = true
            fetchProfile()
        } catch (e: Exception) {
            _errorMessage.value = "인증 처리에 실패했습니다"
        }
    }

    suspend fun signOut() {
        try {
            supabase.auth.signOut()
            _isAuthenticated.value = false
            _currentProfile.value = null
            context.dataStore.edit { it.clear() }
        } catch (e: Exception) {
            _errorMessage.value = "로그아웃에 실패했습니다"
        }
    }

    suspend fun fetchProfile() {
        val userId = currentUserId ?: return
        try {
            val profile = supabase.postgrest.from("profiles")
                .select { filter { eq("id", userId) } }
                .decodeSingleOrNull<ProfileDTO>()
            _currentProfile.value = profile
        } catch (_: Exception) {}
    }

    suspend fun saveWorkspaceId(id: String) {
        context.dataStore.edit { prefs ->
            prefs[stringPreferencesKey("current_workspace_id")] = id
        }
    }

    suspend fun getSavedWorkspaceId(): String? {
        return context.dataStore.data.map { prefs ->
            prefs[stringPreferencesKey("current_workspace_id")]
        }.first()
    }

    fun clearError() { _errorMessage.value = null }
}

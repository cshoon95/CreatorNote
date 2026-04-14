package com.soohoon.influe.data.repository

import android.content.Context
import com.soohoon.influe.data.model.*
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.data.supabase.SupabaseClient
import com.soohoon.influe.data.supabase.WorkspaceManager
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

class DataRepository(
    private val context: Context,
    private val authManager: AuthManager,
    private val workspaceManager: WorkspaceManager
) {
    private val supabase = SupabaseClient.client
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    private val _sponsorships = MutableStateFlow<List<SponsorshipDTO>>(emptyList())
    val sponsorships: StateFlow<List<SponsorshipDTO>> = _sponsorships.asStateFlow()

    private val _settlements = MutableStateFlow<List<SettlementDTO>>(emptyList())
    val settlements: StateFlow<List<SettlementDTO>> = _settlements.asStateFlow()

    private val _reelsNotes = MutableStateFlow<List<ReelsNoteDTO>>(emptyList())
    val reelsNotes: StateFlow<List<ReelsNoteDTO>> = _reelsNotes.asStateFlow()

    private val _generalNotes = MutableStateFlow<List<GeneralNoteDTO>>(emptyList())
    val generalNotes: StateFlow<List<GeneralNoteDTO>> = _generalNotes.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val cacheDir get() = File(context.cacheDir, "DataCache").apply { mkdirs() }

    init {
        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
            loadCache()
        }
    }

    // MARK: - Fetch All
    suspend fun fetchAll() {
        val wsId = workspaceManager.currentWorkspaceId ?: return
        _isLoading.value = true
        try {
            coroutineScope {
                launch { fetchSponsorships(wsId) }
                launch { fetchSettlements(wsId) }
                launch { fetchReelsNotes(wsId) }
                launch { fetchGeneralNotes(wsId) }
            }
            saveCache()
        } finally {
            _isLoading.value = false
        }
    }

    // MARK: - Sponsorships
    private suspend fun fetchSponsorships(wsId: String) {
        try {
            _sponsorships.value = supabase.postgrest.from("sponsorships")
                .select { filter { eq("workspace_id", wsId) }; order("end_date", order = Order.ASCENDING) }
                .decodeList()
        } catch (_: Exception) { showError("협찬 목록을 불러올 수 없습니다") }
    }

    suspend fun createSponsorship(insert: SponsorshipInsert): SponsorshipDTO? {
        return try {
            val created = supabase.postgrest.from("sponsorships")
                .insert(insert) { select() }
                .decodeSingle<SponsorshipDTO>()
            _sponsorships.value = listOf(created) + _sponsorships.value
            created
        } catch (e: Exception) {
            showError("협찬 추가 실패: ${e.localizedMessage}")
            null
        }
    }

    suspend fun updateSponsorship(item: SponsorshipDTO) {
        val idx = _sponsorships.value.indexOfFirst { it.id == item.id }
        if (idx >= 0) {
            _sponsorships.value = _sponsorships.value.toMutableList().apply { set(idx, item) }
        }
        try {
            supabase.postgrest.from("sponsorships")
                .update(item) { filter { eq("id", item.id) } }
        } catch (_: Exception) {
            workspaceManager.currentWorkspaceId?.let { fetchSponsorships(it) }
            showError("협찬 수정에 실패했습니다")
        }
    }

    suspend fun deleteSponsorship(id: String) {
        val backup = _sponsorships.value
        _sponsorships.value = _sponsorships.value.filter { it.id != id }
        try {
            supabase.postgrest.from("sponsorships")
                .delete { filter { eq("id", id) } }
        } catch (_: Exception) {
            _sponsorships.value = backup
            showError("삭제에 실패했습니다")
        }
    }

    // MARK: - Settlements
    private suspend fun fetchSettlements(wsId: String) {
        try {
            _settlements.value = supabase.postgrest.from("settlements")
                .select { filter { eq("workspace_id", wsId) }; order("created_at", order = Order.DESCENDING) }
                .decodeList()
        } catch (_: Exception) { showError("정산 목록을 불러올 수 없습니다") }
    }

    suspend fun createSettlement(insert: SettlementInsert): SettlementDTO? {
        return try {
            val created = supabase.postgrest.from("settlements")
                .insert(insert) { select() }
                .decodeSingle<SettlementDTO>()
            _settlements.value = listOf(created) + _settlements.value
            created
        } catch (e: Exception) {
            showError("정산 추가에 실패했습니다: ${e.localizedMessage}")
            null
        }
    }

    suspend fun updateSettlement(item: SettlementDTO) {
        val idx = _settlements.value.indexOfFirst { it.id == item.id }
        if (idx >= 0) {
            _settlements.value = _settlements.value.toMutableList().apply { set(idx, item) }
        }
        try {
            supabase.postgrest.from("settlements")
                .update(item) { filter { eq("id", item.id) } }
        } catch (_: Exception) {
            workspaceManager.currentWorkspaceId?.let { fetchSettlements(it) }
            showError("정산 수정에 실패했습니다")
        }
    }

    suspend fun deleteSettlement(id: String) {
        val backup = _settlements.value
        _settlements.value = _settlements.value.filter { it.id != id }
        try {
            supabase.postgrest.from("settlements")
                .delete { filter { eq("id", id) } }
        } catch (_: Exception) {
            _settlements.value = backup
            showError("삭제에 실패했습니다")
        }
    }

    // MARK: - Reels Notes
    private suspend fun fetchReelsNotes(wsId: String) {
        try {
            _reelsNotes.value = supabase.postgrest.from("reels_notes")
                .select { filter { eq("workspace_id", wsId) }; order("updated_at", order = Order.DESCENDING) }
                .decodeList()
        } catch (_: Exception) { showError("릴스 노트를 불러올 수 없습니다") }
    }

    suspend fun createReelsNote(insert: ReelsNoteInsert): ReelsNoteDTO? {
        return try {
            val created = supabase.postgrest.from("reels_notes")
                .insert(insert) { select() }
                .decodeSingle<ReelsNoteDTO>()
            _reelsNotes.value = listOf(created) + _reelsNotes.value
            created
        } catch (e: Exception) {
            showError("릴스 노트 추가에 실패했습니다: ${e.localizedMessage}")
            null
        }
    }

    suspend fun updateReelsNote(item: ReelsNoteDTO) {
        val idx = _reelsNotes.value.indexOfFirst { it.id == item.id }
        if (idx >= 0) {
            _reelsNotes.value = _reelsNotes.value.toMutableList().apply { set(idx, item) }
        }
        try {
            supabase.postgrest.from("reels_notes")
                .update(item) { filter { eq("id", item.id) } }
        } catch (_: Exception) {
            workspaceManager.currentWorkspaceId?.let { fetchReelsNotes(it) }
            showError("릴스 노트 수정에 실패했습니다")
        }
    }

    suspend fun deleteReelsNote(id: String) {
        val backup = _reelsNotes.value
        _reelsNotes.value = _reelsNotes.value.filter { it.id != id }
        try {
            supabase.postgrest.from("reels_notes")
                .delete { filter { eq("id", id) } }
        } catch (_: Exception) {
            _reelsNotes.value = backup
            showError("삭제에 실패했습니다")
        }
    }

    // MARK: - General Notes
    private suspend fun fetchGeneralNotes(wsId: String) {
        try {
            _generalNotes.value = supabase.postgrest.from("general_notes")
                .select { filter { eq("workspace_id", wsId) }; order("updated_at", order = Order.DESCENDING) }
                .decodeList()
        } catch (_: Exception) { showError("메모를 불러올 수 없습니다") }
    }

    suspend fun createGeneralNote(insert: GeneralNoteInsert): GeneralNoteDTO? {
        return try {
            val created = supabase.postgrest.from("general_notes")
                .insert(insert) { select() }
                .decodeSingle<GeneralNoteDTO>()
            _generalNotes.value = listOf(created) + _generalNotes.value
            created
        } catch (e: Exception) {
            showError("메모 추가에 실패했습니다: ${e.localizedMessage}")
            null
        }
    }

    suspend fun updateGeneralNote(item: GeneralNoteDTO) {
        val idx = _generalNotes.value.indexOfFirst { it.id == item.id }
        if (idx >= 0) {
            _generalNotes.value = _generalNotes.value.toMutableList().apply { set(idx, item) }
        }
        try {
            supabase.postgrest.from("general_notes")
                .update(item) { filter { eq("id", item.id) } }
        } catch (_: Exception) {
            workspaceManager.currentWorkspaceId?.let { fetchGeneralNotes(it) }
            showError("메모 수정에 실패했습니다")
        }
    }

    suspend fun deleteGeneralNote(id: String) {
        val backup = _generalNotes.value
        _generalNotes.value = _generalNotes.value.filter { it.id != id }
        try {
            supabase.postgrest.from("general_notes")
                .delete { filter { eq("id", id) } }
        } catch (_: Exception) {
            _generalNotes.value = backup
            showError("삭제에 실패했습니다")
        }
    }

    // MARK: - Cache
    private fun saveCache() {
        try {
            File(cacheDir, "sponsorships.json").writeText(json.encodeToString(_sponsorships.value))
            File(cacheDir, "settlements.json").writeText(json.encodeToString(_settlements.value))
            File(cacheDir, "reelsNotes.json").writeText(json.encodeToString(_reelsNotes.value))
            File(cacheDir, "generalNotes.json").writeText(json.encodeToString(_generalNotes.value))
        } catch (_: Exception) {}
    }

    private fun loadCache() {
        try {
            File(cacheDir, "sponsorships.json").takeIf { it.exists() }?.let {
                _sponsorships.value = json.decodeFromString(it.readText())
            }
            File(cacheDir, "settlements.json").takeIf { it.exists() }?.let {
                _settlements.value = json.decodeFromString(it.readText())
            }
            File(cacheDir, "reelsNotes.json").takeIf { it.exists() }?.let {
                _reelsNotes.value = json.decodeFromString(it.readText())
            }
            File(cacheDir, "generalNotes.json").takeIf { it.exists() }?.let {
                _generalNotes.value = json.decodeFromString(it.readText())
            }
        } catch (_: Exception) {}
    }

    private fun showError(msg: String) {
        _errorMessage.value = msg
    }

    fun clearError() { _errorMessage.value = null }
}

package com.soohoon.influe.data.supabase

import com.soohoon.influe.data.model.InviteCodeDTO
import com.soohoon.influe.data.model.ProfileDTO
import com.soohoon.influe.data.model.WorkspaceDTO
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class WorkspaceManager(private val authManager: AuthManager) {
    private val supabase = SupabaseClient.client

    private val _currentWorkspace = MutableStateFlow<WorkspaceDTO?>(null)
    val currentWorkspace: StateFlow<WorkspaceDTO?> = _currentWorkspace.asStateFlow()

    private val _workspaces = MutableStateFlow<List<WorkspaceDTO>>(emptyList())
    val workspaces: StateFlow<List<WorkspaceDTO>> = _workspaces.asStateFlow()

    private val _members = MutableStateFlow<List<ProfileDTO>>(emptyList())
    val members: StateFlow<List<ProfileDTO>> = _members.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    val currentWorkspaceId: String? get() = _currentWorkspace.value?.id

    suspend fun fetchWorkspaces() {
        val userId = authManager.currentUserId ?: return
        try {
            val memberRows = supabase.postgrest.from("workspace_members")
                .select { filter { eq("user_id", userId) } }
                .decodeList<WorkspaceMemberRow>()

            val wsIds = memberRows.map { it.workspaceId }
            if (wsIds.isEmpty()) return

            val list = supabase.postgrest.from("workspaces")
                .select { filter { isIn("id", wsIds) } }
                .decodeList<WorkspaceDTO>()
            _workspaces.value = list

            val savedId = authManager.getSavedWorkspaceId()
            if (_currentWorkspace.value == null) {
                _currentWorkspace.value = list.find { it.id == savedId } ?: list.firstOrNull()
                _currentWorkspace.value?.let { authManager.saveWorkspaceId(it.id) }
            }
        } catch (e: Exception) {
            _errorMessage.value = "워크스페이스를 불러올 수 없습니다"
        }
    }

    suspend fun selectWorkspace(id: String) {
        _currentWorkspace.value = _workspaces.value.find { it.id == id }
        authManager.saveWorkspaceId(id)
    }

    suspend fun createWorkspace(name: String) {
        val userId = authManager.currentUserId ?: return
        _isLoading.value = true
        try {
            val ws = supabase.postgrest.from("workspaces")
                .insert(buildJsonObject {
                    put("name", name)
                    put("owner_id", userId)
                }) { select() }
                .decodeSingle<WorkspaceDTO>()

            supabase.postgrest.from("workspace_members")
                .insert(buildJsonObject {
                    put("workspace_id", ws.id)
                    put("user_id", userId)
                    put("role", "owner")
                })

            _workspaces.value = _workspaces.value + ws
            _currentWorkspace.value = ws
            authManager.saveWorkspaceId(ws.id)
        } catch (e: Exception) {
            _errorMessage.value = "워크스페이스 생성에 실패했습니다"
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun generateInviteCode(): String? {
        val wsId = currentWorkspaceId ?: return null
        try {
            val code = supabase.postgrest.from("invite_codes")
                .insert(buildJsonObject {
                    put("workspace_id", wsId)
                    put("max_uses", 5)
                }) { select() }
                .decodeSingle<InviteCodeDTO>()
            return code.code
        } catch (e: Exception) {
            _errorMessage.value = "초대 코드 생성에 실패했습니다"
            return null
        }
    }

    suspend fun joinWithCode(code: String) {
        _isLoading.value = true
        try {
            supabase.postgrest.rpc("join_workspace_by_code", buildJsonObject {
                put("invite_code_input", code)
            })
            fetchWorkspaces()
        } catch (e: Exception) {
            _errorMessage.value = "초대 코드가 유효하지 않습니다"
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun fetchMembers() {
        val wsId = currentWorkspaceId ?: return
        try {
            val memberRows = supabase.postgrest.from("workspace_members")
                .select { filter { eq("workspace_id", wsId) } }
                .decodeList<WorkspaceMemberRow>()

            val userIds = memberRows.map { it.userId }
            if (userIds.isEmpty()) return

            _members.value = supabase.postgrest.from("profiles")
                .select { filter { isIn("id", userIds) } }
                .decodeList<ProfileDTO>()
        } catch (_: Exception) {}
    }

    suspend fun leaveWorkspace() {
        val wsId = currentWorkspaceId ?: return
        val userId = authManager.currentUserId ?: return
        try {
            supabase.postgrest.from("workspace_members")
                .delete { filter { eq("workspace_id", wsId); eq("user_id", userId) } }
            _currentWorkspace.value = null
            fetchWorkspaces()
        } catch (e: Exception) {
            _errorMessage.value = "워크스페이스 나가기에 실패했습니다"
        }
    }
}

@Serializable
private data class WorkspaceMemberRow(
    @kotlinx.serialization.SerialName("workspace_id") val workspaceId: String,
    @kotlinx.serialization.SerialName("user_id") val userId: String,
    val role: String = "member"
)

package com.soohoon.influe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ProfileDTO(
    val id: String,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    val provider: String? = null,
    @SerialName("created_at") val createdAt: String = ""
)

@Serializable
data class WorkspaceDTO(
    val id: String,
    val name: String,
    @SerialName("owner_id") val ownerId: String,
    @SerialName("created_at") val createdAt: String = ""
)

@Serializable
data class WorkspaceMemberDTO(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("user_id") val userId: String,
    val role: String = "member"
)

@Serializable
data class InviteCodeDTO(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val code: String,
    @SerialName("expires_at") val expiresAt: String,
    @SerialName("max_uses") val maxUses: Int = 5,
    @SerialName("used_count") val usedCount: Int = 0,
    @SerialName("is_active") val isActive: Boolean = true
)

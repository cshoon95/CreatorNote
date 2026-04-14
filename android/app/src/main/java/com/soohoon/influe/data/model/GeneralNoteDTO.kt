package com.soohoon.influe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class GeneralNoteDTO(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val title: String = "",
    @SerialName("attributed_content") val attributedContent: String? = null,
    @SerialName("plain_content") val plainContent: String = "",
    val tags: List<String> = emptyList(),
    @SerialName("is_pinned") val isPinned: Boolean = false,
    @SerialName("created_by") val createdBy: String? = null,
    @SerialName("created_at") val createdAt: String = "",
    @SerialName("updated_at") val updatedAt: String = ""
)

@Serializable
data class GeneralNoteInsert(
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("created_by") val createdBy: String,
    val title: String = "",
    @SerialName("plain_content") val plainContent: String = "",
    @SerialName("attributed_content") val attributedContent: String? = null,
    val tags: List<String> = emptyList()
)

package com.soohoon.influe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

enum class ReelsNoteStatus(val rawValue: String, val displayName: String) {
    DRAFTING("drafting", "작성중"),
    READY_TO_UPLOAD("readyToUpload", "업로드 대기"),
    UPLOADED("uploaded", "업로드 완료");

    companion object {
        fun fromRawValue(raw: String): ReelsNoteStatus =
            entries.find { it.rawValue == raw } ?: DRAFTING
    }
}

@Serializable
data class ReelsNoteDTO(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val title: String = "",
    @SerialName("attributed_content") val attributedContent: String? = null,
    @SerialName("plain_content") val plainContent: String = "",
    val status: String = "drafting",
    @SerialName("sponsorship_id") val sponsorshipId: String? = null,
    val tags: List<String> = emptyList(),
    @SerialName("is_pinned") val isPinned: Boolean = false,
    @SerialName("created_by") val createdBy: String? = null,
    @SerialName("created_at") val createdAt: String = "",
    @SerialName("updated_at") val updatedAt: String = ""
) {
    val reelsNoteStatus: ReelsNoteStatus
        get() = ReelsNoteStatus.fromRawValue(status)
}

@Serializable
data class ReelsNoteInsert(
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("created_by") val createdBy: String,
    val title: String = "",
    @SerialName("plain_content") val plainContent: String = "",
    @SerialName("attributed_content") val attributedContent: String? = null,
    val status: String = "drafting",
    val tags: List<String> = emptyList()
)

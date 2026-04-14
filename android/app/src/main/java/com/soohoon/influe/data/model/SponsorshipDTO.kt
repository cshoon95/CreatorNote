package com.soohoon.influe.data.model

import kotlinx.datetime.Instant
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.daysUntil
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

enum class SponsorshipStatus(val rawValue: String, val displayName: String) {
    PRE_SUBMIT("preSubmit", "제출 전"),
    UNDER_REVIEW("underReview", "검수중"),
    SUBMITTED("submitted", "제출 완료"),
    PENDING_SETTLEMENT("pendingSettlement", "정산 대기"),
    COMPLETED("completed", "완료");

    companion object {
        fun fromRawValue(raw: String): SponsorshipStatus =
            entries.find { it.rawValue == raw } ?: PRE_SUBMIT
    }
}

@Serializable
data class SponsorshipDTO(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("brand_name") val brandName: String,
    @SerialName("product_name") val productName: String = "",
    val details: String = "",
    val amount: Double = 0.0,
    @SerialName("start_date") val startDate: String, // ISO 8601
    @SerialName("end_date") val endDate: String,
    val status: String = "preSubmit",
    @SerialName("created_by") val createdBy: String? = null,
    @SerialName("created_at") val createdAt: String = "",
    @SerialName("updated_at") val updatedAt: String = ""
) {
    val sponsorshipStatus: SponsorshipStatus
        get() = SponsorshipStatus.fromRawValue(status)

    val daysRemaining: Int
        get() = try {
            val end = Instant.parse(endDate)
            val now = Clock.System.now()
            now.daysUntil(end, TimeZone.currentSystemDefault())
        } catch (_: Exception) { 0 }

    val isExpired: Boolean get() = daysRemaining < 0

    val isExpiringSoon: Boolean get() = daysRemaining in 0..3
}

@Serializable
data class SponsorshipInsert(
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("created_by") val createdBy: String,
    @SerialName("brand_name") val brandName: String,
    @SerialName("product_name") val productName: String = "",
    val details: String = "",
    val amount: Double = 0.0,
    @SerialName("start_date") val startDate: String,
    @SerialName("end_date") val endDate: String,
    val status: String = "preSubmit"
)

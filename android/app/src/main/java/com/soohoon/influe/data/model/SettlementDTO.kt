package com.soohoon.influe.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SettlementDTO(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("sponsorship_id") val sponsorshipId: String? = null,
    @SerialName("brand_name") val brandName: String,
    val amount: Double = 0.0,
    val fee: Double = 0.0,
    val tax: Double = 0.0,
    @SerialName("settlement_date") val settlementDate: String? = null,
    @SerialName("is_paid") val isPaid: Boolean = false,
    val memo: String = "",
    @SerialName("created_by") val createdBy: String? = null,
    @SerialName("created_at") val createdAt: String = ""
) {
    val netAmount: Double get() = amount - fee - tax
}

@Serializable
data class SettlementInsert(
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("created_by") val createdBy: String,
    @SerialName("brand_name") val brandName: String,
    val amount: Double = 0.0,
    val fee: Double = 0.0,
    val tax: Double = 0.0,
    @SerialName("settlement_date") val settlementDate: String? = null,
    @SerialName("is_paid") val isPaid: Boolean = false,
    val memo: String = "",
    @SerialName("sponsorship_id") val sponsorshipId: String? = null
)

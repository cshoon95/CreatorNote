package com.soohoon.influe.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.model.ReelsNoteStatus
import com.soohoon.influe.data.model.SponsorshipStatus
import com.soohoon.influe.ui.theme.AppTheme
import com.soohoon.influe.ui.theme.LocalAppTheme

@Composable
fun ThemedCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    val theme = LocalAppTheme.current
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = theme.cardBackground),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp), content = content)
    }
}

@Composable
fun EmptyStateView(
    icon: String,
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier
) {
    val theme = LocalAppTheme.current
    Column(
        modifier = modifier.fillMaxWidth().padding(40.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(icon, fontSize = 48.sp)
        Spacer(Modifier.height(16.dp))
        Text(title, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = theme.textPrimary)
        Spacer(Modifier.height(8.dp))
        Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = theme.textSecondary, textAlign = TextAlign.Center)
    }
}

@Composable
fun GradientAvatar(
    text: String,
    gradient: List<Color>,
    size: Int = 44,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(size.dp)
            .clip(CircleShape)
            .background(Brush.linearGradient(gradient)),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text.take(1),
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = (size / 3).sp
        )
    }
}

@Composable
fun SponsorshipStatusBadge(status: SponsorshipStatus) {
    val (bg, fg) = when (status) {
        SponsorshipStatus.PRE_SUBMIT -> Color(0xFFF3F4F6) to Color(0xFF6B7280)
        SponsorshipStatus.UNDER_REVIEW -> Color(0xFFFEF3C7) to Color(0xFFF59E0B)
        SponsorshipStatus.SUBMITTED -> Color(0xFFDBEAFE) to Color(0xFF3B82F6)
        SponsorshipStatus.PENDING_SETTLEMENT -> Color(0xFFFED7AA) to Color(0xFFF97316)
        SponsorshipStatus.COMPLETED -> Color(0xFFD1FAE5) to Color(0xFF10B981)
    }
    Text(
        text = status.displayName,
        color = fg,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier
            .background(bg, RoundedCornerShape(12.dp))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    )
}

@Composable
fun ReelsNoteStatusBadge(status: ReelsNoteStatus) {
    val (bg, fg) = when (status) {
        ReelsNoteStatus.DRAFTING -> Color(0xFFFED7AA) to Color(0xFFF97316)
        ReelsNoteStatus.READY_TO_UPLOAD -> Color(0xFFDBEAFE) to Color(0xFF3B82F6)
        ReelsNoteStatus.UPLOADED -> Color(0xFFD1FAE5) to Color(0xFF10B981)
    }
    Text(
        text = status.displayName,
        color = fg,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier
            .background(bg, RoundedCornerShape(12.dp))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    )
}

fun reelsNoteStatusColor(status: ReelsNoteStatus): Color {
    return when (status) {
        ReelsNoteStatus.DRAFTING -> Color(0xFFF97316)
        ReelsNoteStatus.READY_TO_UPLOAD -> Color(0xFF3B82F6)
        ReelsNoteStatus.UPLOADED -> Color(0xFF10B981)
    }
}

package com.soohoon.influe.ui.screens.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.repository.DataRepository
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.ui.components.ReelsNoteStatusBadge
import com.soohoon.influe.ui.components.ThemedCard
import com.soohoon.influe.ui.components.reelsNoteStatusColor
import com.soohoon.influe.ui.theme.LocalAppTheme
import com.soohoon.influe.ui.theme.ThemeManager
import com.soohoon.influe.util.krwFormatted
import java.util.Calendar

@Composable
fun DashboardScreen(
    dataRepository: DataRepository,
    themeManager: ThemeManager,
    authManager: AuthManager,
    onSettingsClick: () -> Unit = {}
) {
    val theme = LocalAppTheme.current
    val sponsorships by dataRepository.sponsorships.collectAsState()
    val reelsNotes by dataRepository.reelsNotes.collectAsState()
    val generalNotes by dataRepository.generalNotes.collectAsState()

    val activeSponsors = remember(sponsorships) { sponsorships.filter { !it.isExpired } }
    val pendingSettlements = remember(sponsorships) { sponsorships.filter { it.status == "pendingSettlement" } }
    val expiringSoon = remember(sponsorships) { sponsorships.filter { it.isExpiringSoon } }
    val totalEarnings = remember(sponsorships) { sponsorships.filter { it.status == "completed" }.sumOf { it.amount } }

    val greeting = remember {
        when (Calendar.getInstance().get(Calendar.HOUR_OF_DAY)) {
            in 6..11 -> "좋은 아침이에요"
            in 12..17 -> "활기찬 오후에요"
            in 18..21 -> "수고한 하루에요"
            else -> "늦은 밤이에요"
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(bottom = 16.dp)
    ) {
        // Settings button
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.End
        ) {
            Icon(
                Icons.Default.Settings, "설정",
                tint = theme.textSecondary,
                modifier = Modifier
                    .size(28.dp)
                    .clickable(interactionSource = null, indication = null) { onSettingsClick() }
            )
        }

        // Header card
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
                .height(160.dp)
                .clip(RoundedCornerShape(24.dp))
                .background(Brush.linearGradient(theme.gradient))
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.Bottom
            ) {
                Text(greeting, fontSize = 14.sp, color = Color.White.copy(alpha = 0.85f))
                Spacer(Modifier.height(8.dp))
                Text("Influe", fontSize = 32.sp, fontWeight = FontWeight.Bold, color = Color.White)
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Column {
                        Text("${activeSponsors.size}건", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        Text("진행중", fontSize = 12.sp, color = Color.White.copy(alpha = 0.75f))
                    }
                    Box(Modifier.width(1.dp).height(28.dp).background(Color.White.copy(alpha = 0.3f)))
                    Column {
                        Text("${pendingSettlements.size}건", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        Text("정산 대기", fontSize = 12.sp, color = Color.White.copy(alpha = 0.75f))
                    }
                    Box(Modifier.width(1.dp).height(28.dp).background(Color.White.copy(alpha = 0.3f)))
                    Column {
                        Text("${expiringSoon.size}건", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        Text("마감 임박", fontSize = 12.sp, color = Color.White.copy(alpha = 0.75f))
                    }
                }
            }
        }

        // Stats
        Row(
            modifier = Modifier.padding(horizontal = 16.dp).padding(top = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ThemedCard(modifier = Modifier.weight(1f)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Icon(Icons.Default.Paid, null, tint = theme.primary)
                    Text("총 수익", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = theme.textSecondary)
                }
                Spacer(Modifier.height(8.dp))
                Text(totalEarnings.krwFormatted(), fontSize = 18.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary)
                Text("완료된 협찬", fontSize = 12.sp, color = theme.textSecondary)
            }
            ThemedCard(modifier = Modifier.weight(1f)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Icon(Icons.Default.NoteAlt, null, tint = theme.accent)
                    Text("전체 노트", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = theme.textSecondary)
                }
                Spacer(Modifier.height(8.dp))
                Text("${reelsNotes.size + generalNotes.size}", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary)
                Text("릴스 ${reelsNotes.size} · 메모 ${generalNotes.size}", fontSize = 12.sp, color = theme.textSecondary)
            }
        }

        // Recent reels notes
        if (reelsNotes.isNotEmpty()) {
            Spacer(Modifier.height(16.dp))
            Text(
                "최근 릴스 노트",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = theme.textPrimary,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            Spacer(Modifier.height(8.dp))
            reelsNotes.take(3).forEach { note ->
                ThemedCard(modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .width(4.dp).height(44.dp)
                                .clip(RoundedCornerShape(2.dp))
                                .background(reelsNoteStatusColor(note.reelsNoteStatus).copy(alpha = 0.8f))
                        )
                        Spacer(Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                note.title.ifEmpty { "제목 없음" },
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = theme.textPrimary,
                                maxLines = 1
                            )
                            Text(
                                note.plainContent.ifEmpty { "내용 없음" },
                                fontSize = 12.sp,
                                color = theme.textSecondary,
                                maxLines = 1
                            )
                        }
                        ReelsNoteStatusBadge(status = note.reelsNoteStatus)
                    }
                }
            }
        }

        // Empty state
        if (sponsorships.isEmpty() && reelsNotes.isEmpty()) {
            Spacer(Modifier.height(40.dp))
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(Icons.Default.AutoAwesome, null, tint = theme.primary.copy(alpha = 0.5f), modifier = Modifier.size(48.dp))
                Spacer(Modifier.height(16.dp))
                Text("시작해볼까요?", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary)
                Spacer(Modifier.height(8.dp))
                Text("협찬 정보를 추가하거나\n릴스 노트를 작성해보세요", fontSize = 14.sp, color = theme.textSecondary, lineHeight = 20.sp)
            }
        }
    }
}

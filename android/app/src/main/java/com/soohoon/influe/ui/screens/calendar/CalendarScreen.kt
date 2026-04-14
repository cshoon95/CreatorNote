package com.soohoon.influe.ui.screens.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.repository.DataRepository
import com.soohoon.influe.ui.components.GradientAvatar
import com.soohoon.influe.ui.components.ThemedCard
import com.soohoon.influe.ui.theme.LocalAppTheme
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

@Composable
fun CalendarScreen(dataRepository: DataRepository) {
    val theme = LocalAppTheme.current
    val sponsorships by dataRepository.sponsorships.collectAsState()
    var currentMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }

    val daysInMonth = (1..currentMonth.lengthOfMonth()).map { currentMonth.atDay(it) }
    val firstDayOfWeek = (currentMonth.atDay(1).dayOfWeek.value + 6) % 7 // Monday=0

    val weekdays = listOf("월", "화", "수", "목", "금", "토", "일")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(top = 16.dp)
    ) {
        // Month navigation
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.ChevronLeft, null,
                tint = theme.primary,
                modifier = Modifier
                    .size(32.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .clickable(interactionSource = null, indication = null) {
                        currentMonth = currentMonth.minusMonths(1)
                    }
            )
            Spacer(Modifier.weight(1f))
            Text(
                "${currentMonth.year}년 ${currentMonth.monthValue}월",
                fontSize = 18.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary
            )
            Spacer(Modifier.weight(1f))
            Icon(
                Icons.Default.ChevronRight, null,
                tint = theme.primary,
                modifier = Modifier
                    .size(32.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .clickable(interactionSource = null, indication = null) {
                        currentMonth = currentMonth.plusMonths(1)
                    }
            )
        }

        Spacer(Modifier.height(8.dp))

        // Weekday headers
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
            weekdays.forEach { day ->
                Text(
                    day,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = if (day == "토" || day == "일") theme.accent else theme.textSecondary
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        // Calendar grid
        val totalCells = firstDayOfWeek + daysInMonth.size
        val rows = (totalCells + 6) / 7

        for (row in 0 until rows) {
            Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                for (col in 0..6) {
                    val idx = row * 7 + col - firstDayOfWeek
                    if (idx < 0 || idx >= daysInMonth.size) {
                        Box(Modifier.weight(1f).height(44.dp))
                    } else {
                        val date = daysInMonth[idx]
                        val isSelected = date == selectedDate
                        val isToday = date == LocalDate.now()

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(44.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .then(
                                    if (isSelected) Modifier.background(Brush.linearGradient(theme.gradient))
                                    else Modifier
                                )
                                .clickable { selectedDate = date },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "${date.dayOfMonth}",
                                fontSize = 14.sp,
                                fontWeight = if (isToday) FontWeight.Bold else FontWeight.Normal,
                                color = when {
                                    isSelected -> Color.White
                                    isToday -> theme.primary
                                    else -> theme.textPrimary
                                }
                            )
                        }
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        // Selected date details
        Text(
            selectedDate.format(DateTimeFormatter.ofPattern("M월 d일")),
            fontSize = 16.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
        Spacer(Modifier.height(8.dp))

        val selectedSponsors = sponsorships.filter { s ->
            try {
                val start = LocalDate.parse(s.startDate.take(10))
                val end = LocalDate.parse(s.endDate.take(10))
                !selectedDate.isBefore(start) && !selectedDate.isAfter(end)
            } catch (_: Exception) { false }
        }

        if (selectedSponsors.isEmpty()) {
            Text(
                "이 날에 예정된 협찬이 없습니다",
                fontSize = 14.sp, color = theme.textSecondary,
                modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp),
                textAlign = TextAlign.Center
            )
        } else {
            selectedSponsors.forEach { s ->
                ThemedCard(modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        GradientAvatar(s.brandName, theme.gradient, 32)
                        Spacer(Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(s.brandName, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = theme.textPrimary)
                            if (s.productName.isNotEmpty()) {
                                Text(s.productName, fontSize = 12.sp, color = theme.textSecondary)
                            }
                        }
                        Text(
                            if (s.isExpired) "만료" else "D-${s.daysRemaining}",
                            fontWeight = FontWeight.Bold, fontSize = 12.sp,
                            color = if (s.isExpired) theme.danger else theme.primary
                        )
                    }
                }
            }
        }

        Spacer(Modifier.height(96.dp))
    }
}

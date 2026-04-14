package com.soohoon.influe.ui.screens.sponsorship

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.model.SponsorshipDTO
import com.soohoon.influe.data.model.SponsorshipInsert
import com.soohoon.influe.data.model.SponsorshipStatus
import com.soohoon.influe.data.repository.DataRepository
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.data.supabase.WorkspaceManager
import com.soohoon.influe.ui.components.GradientAvatar
import com.soohoon.influe.ui.components.SponsorshipStatusBadge
import com.soohoon.influe.ui.theme.LocalAppTheme
import com.soohoon.influe.util.krwFormatted
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun SponsorshipListScreen(
    dataRepository: DataRepository,
    authManager: AuthManager,
    workspaceManager: WorkspaceManager
) {
    val theme = LocalAppTheme.current
    val scope = rememberCoroutineScope()
    val sponsorships by dataRepository.sponsorships.collectAsState()
    var searchText by remember { mutableStateOf("") }
    var filterStatus by remember { mutableStateOf<SponsorshipStatus?>(null) }
    var showAddSheet by remember { mutableStateOf(false) }

    val filtered = sponsorships
        .filter { filterStatus == null || it.sponsorshipStatus == filterStatus }
        .filter {
            searchText.isEmpty() ||
            it.brandName.contains(searchText, ignoreCase = true) ||
            it.productName.contains(searchText, ignoreCase = true)
        }

    Scaffold(
        containerColor = theme.background,
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddSheet = true },
                shape = CircleShape,
                containerColor = theme.cardBackground,
                contentColor = theme.primary
            ) {
                Icon(Icons.Default.Add, "추가")
            }
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Search
            OutlinedTextField(
                value = searchText,
                onValueChange = { searchText = it },
                placeholder = { Text("브랜드 검색") },
                leadingIcon = { Icon(Icons.Default.Search, null, tint = theme.textSecondary) },
                trailingIcon = {
                    if (searchText.isNotEmpty()) {
                        IconButton(onClick = { searchText = "" }) {
                            Icon(Icons.Default.Clear, null, tint = theme.textSecondary)
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )

            // Filter chips
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(bottom = 12.dp)
            ) {
                item {
                    FilterChip(
                        selected = filterStatus == null,
                        onClick = { filterStatus = null },
                        label = { Text("전체 ${sponsorships.size}") }
                    )
                }
                items(SponsorshipStatus.entries) { status ->
                    val count = sponsorships.count { it.sponsorshipStatus == status }
                    FilterChip(
                        selected = filterStatus == status,
                        onClick = { filterStatus = status },
                        label = { Text("${status.displayName} $count") }
                    )
                }
            }

            if (filtered.isEmpty()) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("협찬 정보가 없어요", color = theme.textSecondary)
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(filtered, key = { it.id }) { item ->
                        var showDeleteDialog by remember { mutableStateOf(false) }
                        Card(
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = theme.cardBackground),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(18.dp)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    GradientAvatar(item.brandName, theme.gradient, 44)
                                    Spacer(Modifier.width(14.dp))
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(item.brandName, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = theme.textPrimary)
                                        if (item.productName.isNotEmpty()) {
                                            Text(item.productName, fontSize = 12.sp, color = theme.textSecondary)
                                        }
                                    }
                                    Column(horizontalAlignment = Alignment.End) {
                                        SponsorshipStatusBadge(item.sponsorshipStatus)
                                        Spacer(Modifier.height(4.dp))
                                        Text(
                                            if (item.isExpired) "만료됨" else "D-${item.daysRemaining}",
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = if (item.isExpired) theme.danger else if (item.isExpiringSoon) theme.warning else theme.primary
                                        )
                                    }
                                    Spacer(Modifier.width(8.dp))
                                    Icon(
                                        Icons.Default.Delete, "삭제",
                                        tint = theme.danger,
                                        modifier = Modifier
                                            .size(20.dp)
                                            .clickable(interactionSource = null, indication = null) { showDeleteDialog = true }
                                    )
                                }
                                if (item.amount > 0) {
                                    HorizontalDivider(color = theme.divider, modifier = Modifier.padding(top = 12.dp))
                                    Row(modifier = Modifier.padding(top = 10.dp)) {
                                        Text("협찬 금액", fontSize = 12.sp, color = theme.textSecondary)
                                        Spacer(Modifier.weight(1f))
                                        Text(item.amount.krwFormatted(), fontWeight = FontWeight.Bold, fontSize = 14.sp, color = theme.primary)
                                    }
                                }
                            }
                        }
                        if (showDeleteDialog) {
                            AlertDialog(
                                onDismissRequest = { showDeleteDialog = false },
                                title = { Text("삭제 확인") },
                                text = { Text("정말 삭제하시겠습니까?") },
                                confirmButton = {
                                    TextButton(onClick = {
                                        scope.launch { dataRepository.deleteSponsorship(item.id) }
                                        showDeleteDialog = false
                                    }) {
                                        Text("삭제", color = theme.danger)
                                    }
                                },
                                dismissButton = {
                                    TextButton(onClick = { showDeleteDialog = false }) {
                                        Text("취소")
                                    }
                                },
                                containerColor = theme.cardBackground
                            )
                        }
                    }
                }
            }
        }
    }

    if (showAddSheet) {
        SponsorshipFormSheet(
            workspaceId = workspaceManager.currentWorkspaceId ?: "",
            userId = authManager.currentUserId ?: "",
            onDismiss = { showAddSheet = false },
            onSave = { insert ->
                scope.launch {
                    dataRepository.createSponsorship(insert)
                    showAddSheet = false
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SponsorshipFormSheet(
    workspaceId: String,
    userId: String,
    onDismiss: () -> Unit,
    onSave: (SponsorshipInsert) -> Unit
) {
    val theme = LocalAppTheme.current
    var brandName by remember { mutableStateOf("") }
    var productName by remember { mutableStateOf("") }
    var amountText by remember { mutableStateOf("") }
    var details by remember { mutableStateOf("") }

    val today = System.currentTimeMillis()
    val startDatePickerState = rememberDatePickerState(initialSelectedDateMillis = today)
    val endDatePickerState = rememberDatePickerState(initialSelectedDateMillis = today + 30L * 24 * 60 * 60 * 1000)
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }

    val dateFormatter = remember { DateTimeFormatter.ofPattern("yyyy-MM-dd") }

    fun millisToDateString(millis: Long?): String {
        if (millis == null) return "날짜 선택"
        return Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).toLocalDate().format(dateFormatter)
    }

    fun millisToIsoString(millis: Long?): String {
        if (millis == null) return Instant.now().toString()
        return Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).toLocalDate().atStartOfDay(ZoneId.systemDefault()).toInstant().toString()
    }

    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = theme.cardBackground) {
        Column(modifier = Modifier.padding(24.dp)) {
            Text("협찬 추가", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary)
            Spacer(Modifier.height(16.dp))
            OutlinedTextField(
                value = brandName, onValueChange = { brandName = it },
                label = { Text("브랜드명 *") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = productName, onValueChange = { productName = it },
                label = { Text("제품명") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = amountText, onValueChange = { amountText = it },
                label = { Text("금액") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = details, onValueChange = { details = it },
                label = { Text("상세 내용") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                minLines = 3
            )
            Spacer(Modifier.height(16.dp))

            // Start date picker
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("시작일", fontSize = 14.sp, color = theme.textPrimary)
                Text(
                    millisToDateString(startDatePickerState.selectedDateMillis),
                    fontSize = 14.sp,
                    color = theme.primary,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.clickable(interactionSource = null, indication = null) { showStartDatePicker = true }
                )
            }
            Spacer(Modifier.height(12.dp))

            // End date picker
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("종료일", fontSize = 14.sp, color = theme.textPrimary)
                Text(
                    millisToDateString(endDatePickerState.selectedDateMillis),
                    fontSize = 14.sp,
                    color = theme.primary,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.clickable(interactionSource = null, indication = null) { showEndDatePicker = true }
                )
            }

            Spacer(Modifier.height(24.dp))
            Button(
                onClick = {
                    onSave(SponsorshipInsert(
                        workspaceId = workspaceId,
                        createdBy = userId,
                        brandName = brandName.trim(),
                        productName = productName.trim(),
                        details = details.trim(),
                        amount = amountText.filter { it.isDigit() }.toDoubleOrNull() ?: 0.0,
                        startDate = millisToIsoString(startDatePickerState.selectedDateMillis),
                        endDate = millisToIsoString(endDatePickerState.selectedDateMillis)
                    ))
                },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = RoundedCornerShape(12.dp),
                enabled = brandName.isNotBlank(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = theme.primary,
                    contentColor = androidx.compose.ui.graphics.Color.White
                )
            ) {
                Text("저장", fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.height(32.dp))
        }
    }

    if (showStartDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showStartDatePicker = false },
            confirmButton = {
                TextButton(onClick = { showStartDatePicker = false }) {
                    Text("확인")
                }
            },
            dismissButton = {
                TextButton(onClick = { showStartDatePicker = false }) {
                    Text("취소")
                }
            }
        ) {
            DatePicker(state = startDatePickerState)
        }
    }

    if (showEndDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showEndDatePicker = false },
            confirmButton = {
                TextButton(onClick = { showEndDatePicker = false }) {
                    Text("확인")
                }
            },
            dismissButton = {
                TextButton(onClick = { showEndDatePicker = false }) {
                    Text("취소")
                }
            }
        ) {
            DatePicker(state = endDatePickerState)
        }
    }
}

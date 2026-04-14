package com.soohoon.influe.ui.screens.settlement

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.soohoon.influe.data.model.SettlementInsert
import com.soohoon.influe.data.repository.DataRepository
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.data.supabase.WorkspaceManager
import com.soohoon.influe.ui.theme.LocalAppTheme
import com.soohoon.influe.util.krwFormatted
import kotlinx.coroutines.launch

enum class SettlementFilter(val label: String) { ALL("전체"), PENDING("대기중"), PAID("완료") }

@Composable
fun SettlementListScreen(
    dataRepository: DataRepository,
    authManager: AuthManager,
    workspaceManager: WorkspaceManager
) {
    val theme = LocalAppTheme.current
    val scope = rememberCoroutineScope()
    val settlements by dataRepository.settlements.collectAsState()
    var filter by remember { mutableStateOf(SettlementFilter.ALL) }
    var showAddSheet by remember { mutableStateOf(false) }

    val filtered = remember(settlements, filter) {
        when (filter) {
            SettlementFilter.ALL -> settlements
            SettlementFilter.PENDING -> settlements.filter { !it.isPaid }
            SettlementFilter.PAID -> settlements.filter { it.isPaid }
        }
    }

    val totalNet = remember(settlements) { settlements.sumOf { it.netAmount } }
    val paidTotal = remember(settlements) { settlements.filter { it.isPaid }.sumOf { it.netAmount } }
    val pendingTotal = remember(settlements) { settlements.filter { !it.isPaid }.sumOf { it.netAmount } }

    Scaffold(
        containerColor = theme.background,
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddSheet = true },
                shape = CircleShape,
                containerColor = theme.cardBackground,
                contentColor = theme.primary
            ) { Icon(Icons.Default.Add, "추가") }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.padding(padding),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Hero card
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(24.dp))
                        .background(Brush.linearGradient(theme.gradient))
                ) {
                    Column {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(top = 28.dp, bottom = 24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("총 실수령액", fontSize = 14.sp, color = Color.White.copy(alpha = 0.8f))
                            Text(totalNet.krwFormatted(), fontSize = 32.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        }
                        Box(
                            Modifier
                                .fillMaxWidth()
                                .height(1.dp)
                                .padding(horizontal = 20.dp)
                                .background(Color.White.copy(alpha = 0.2f))
                        )
                        Row(Modifier.fillMaxWidth().padding(vertical = 18.dp)) {
                            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("지급 완료", fontSize = 12.sp, color = Color.White.copy(alpha = 0.75f))
                                Text(paidTotal.krwFormatted(), fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                            Box(
                                Modifier
                                    .width(1.dp)
                                    .height(36.dp)
                                    .background(Color.White.copy(alpha = 0.2f))
                            )
                            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("대기중", fontSize = 12.sp, color = Color.White.copy(alpha = 0.75f))
                                Text(pendingTotal.krwFormatted(), fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                        }
                    }
                }
            }

            // Filter tabs
            item {
                Row(
                    modifier = Modifier.padding(horizontal = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    SettlementFilter.entries.forEach { tab ->
                        Text(
                            tab.label,
                            fontWeight = if (filter == tab) FontWeight.Bold else FontWeight.Normal,
                            color = if (filter == tab) theme.textPrimary else theme.textSecondary,
                            fontSize = 14.sp,
                            modifier = Modifier
                                .clickable(interactionSource = null, indication = null) { filter = tab }
                                .padding(vertical = 4.dp)
                        )
                    }
                }
            }

            if (filtered.isEmpty()) {
                item {
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 40.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("정산 내역이 없습니다", color = theme.textSecondary)
                    }
                }
            }

            // List
            items(filtered, key = { it.id }) { item ->
                var showDeleteDialog by remember { mutableStateOf(false) }
                Card(
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = theme.cardBackground)
                ) {
                    Row(modifier = Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .background(if (item.isPaid) Color(0x2634C759) else Color(0x26FF9500)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                if (item.isPaid) Icons.Default.CheckCircle else Icons.Default.Schedule,
                                null,
                                tint = if (item.isPaid) Color(0xFF34C759) else Color(0xFFFF9500)
                            )
                        }
                        Spacer(Modifier.width(14.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(item.brandName, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = theme.textPrimary)
                            Text(
                                if (item.isPaid) "지급 완료" else "대기중",
                                fontSize = 12.sp,
                                color = theme.textSecondary
                            )
                        }
                        Text(
                            item.netAmount.krwFormatted(),
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = theme.textPrimary
                        )
                        Spacer(Modifier.width(8.dp))
                        Icon(
                            Icons.Default.Delete, "삭제",
                            tint = theme.danger,
                            modifier = Modifier
                                .size(20.dp)
                                .clickable(interactionSource = null, indication = null) { showDeleteDialog = true }
                        )
                    }
                }
                if (showDeleteDialog) {
                    AlertDialog(
                        onDismissRequest = { showDeleteDialog = false },
                        title = { Text("삭제 확인") },
                        text = { Text("정말 삭제하시겠습니까?") },
                        confirmButton = {
                            TextButton(onClick = {
                                scope.launch { dataRepository.deleteSettlement(item.id) }
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

    if (showAddSheet) {
        SettlementFormSheet(
            workspaceId = workspaceManager.currentWorkspaceId ?: "",
            userId = authManager.currentUserId ?: "",
            onDismiss = { showAddSheet = false },
            onSave = { insert ->
                scope.launch {
                    dataRepository.createSettlement(insert)
                    showAddSheet = false
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettlementFormSheet(
    workspaceId: String,
    userId: String,
    onDismiss: () -> Unit,
    onSave: (SettlementInsert) -> Unit
) {
    val theme = LocalAppTheme.current
    var brandName by remember { mutableStateOf("") }
    var amountText by remember { mutableStateOf("") }
    var feeText by remember { mutableStateOf("") }
    var taxText by remember { mutableStateOf("") }
    var memo by remember { mutableStateOf("") }
    var isPaid by remember { mutableStateOf(false) }

    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = theme.cardBackground) {
        Column(modifier = Modifier.padding(24.dp)) {
            Text("정산 추가", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary)
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
                value = amountText, onValueChange = { amountText = it },
                label = { Text("금액") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )
            Spacer(Modifier.height(12.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = feeText, onValueChange = { feeText = it },
                    label = { Text("수수료") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true
                )
                OutlinedTextField(
                    value = taxText, onValueChange = { taxText = it },
                    label = { Text("세금") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true
                )
            }
            Spacer(Modifier.height(12.dp))

            OutlinedTextField(
                value = memo, onValueChange = { memo = it },
                label = { Text("메모") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                minLines = 2
            )
            Spacer(Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("지급 완료", fontSize = 14.sp, color = theme.textPrimary)
                Switch(
                    checked = isPaid,
                    onCheckedChange = { isPaid = it },
                    colors = SwitchDefaults.colors(checkedTrackColor = theme.primary)
                )
            }

            Spacer(Modifier.height(24.dp))

            Button(
                onClick = {
                    onSave(SettlementInsert(
                        workspaceId = workspaceId,
                        createdBy = userId,
                        brandName = brandName.trim(),
                        amount = amountText.filter { it.isDigit() }.toDoubleOrNull() ?: 0.0,
                        fee = feeText.filter { it.isDigit() }.toDoubleOrNull() ?: 0.0,
                        tax = taxText.filter { it.isDigit() }.toDoubleOrNull() ?: 0.0,
                        memo = memo.trim(),
                        isPaid = isPaid
                    ))
                },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = RoundedCornerShape(12.dp),
                enabled = brandName.isNotBlank(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = theme.primary,
                    contentColor = Color.White
                )
            ) {
                Text("저장", fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.height(32.dp))
        }
    }
}

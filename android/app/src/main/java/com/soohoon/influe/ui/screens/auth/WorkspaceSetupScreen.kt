package com.soohoon.influe.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.supabase.WorkspaceManager
import com.soohoon.influe.ui.theme.LocalAppTheme
import kotlinx.coroutines.launch

@Composable
fun WorkspaceSetupScreen(workspaceManager: WorkspaceManager) {
    val theme = LocalAppTheme.current
    val scope = rememberCoroutineScope()
    val isLoading by workspaceManager.isLoading.collectAsState()
    var workspaceName by remember { mutableStateOf("") }
    var inviteCode by remember { mutableStateOf("") }
    var showJoin by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.linearGradient(theme.gradient)),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier.fillMaxWidth(0.85f),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(
                modifier = Modifier.padding(28.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text("워크스페이스 설정", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1A1A1A))
                Spacer(Modifier.height(8.dp))
                Text("협찬 데이터를 관리할 공간을 만들어주세요", fontSize = 14.sp, color = Color(0xFF6B7280))
                Spacer(Modifier.height(24.dp))

                if (!showJoin) {
                    OutlinedTextField(
                        value = workspaceName,
                        onValueChange = { workspaceName = it },
                        label = { Text("워크스페이스 이름") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    Spacer(Modifier.height(16.dp))
                    Button(
                        onClick = {
                            if (workspaceName.isNotBlank()) {
                                scope.launch { workspaceManager.createWorkspace(workspaceName.trim()) }
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        enabled = workspaceName.isNotBlank() && !isLoading
                    ) {
                        Text("워크스페이스 만들기", fontWeight = FontWeight.SemiBold)
                    }
                    Spacer(Modifier.height(12.dp))
                    TextButton(onClick = { showJoin = true }) {
                        Text("초대 코드로 참여하기", color = theme.primary)
                    }
                } else {
                    OutlinedTextField(
                        value = inviteCode,
                        onValueChange = { inviteCode = it },
                        label = { Text("초대 코드 (6자리)") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    Spacer(Modifier.height(16.dp))
                    Button(
                        onClick = {
                            if (inviteCode.isNotBlank()) {
                                scope.launch { workspaceManager.joinWithCode(inviteCode.trim()) }
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        enabled = inviteCode.length == 6 && !isLoading
                    ) {
                        Text("참여하기", fontWeight = FontWeight.SemiBold)
                    }
                    Spacer(Modifier.height(12.dp))
                    TextButton(onClick = { showJoin = false }) {
                        Text("새 워크스페이스 만들기", color = theme.primary)
                    }
                }
            }
        }
    }
}

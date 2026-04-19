package com.soohoon.influe.ui.screens.settings

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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.data.supabase.WorkspaceManager
import com.soohoon.influe.ui.theme.AppThemeType
import com.soohoon.influe.ui.theme.LocalAppTheme
import com.soohoon.influe.ui.theme.ThemeManager
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    authManager: AuthManager,
    workspaceManager: WorkspaceManager,
    themeManager: ThemeManager
) {
    val theme = LocalAppTheme.current
    val scope = rememberCoroutineScope()
    val profile by authManager.currentProfile.collectAsState()
    val workspace by workspaceManager.currentWorkspace.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        Text("설정", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = theme.textPrimary)
        Spacer(Modifier.height(20.dp))

        // Profile
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = theme.cardBackground)
        ) {
            Row(
                modifier = Modifier.padding(16.dp).fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(profile?.displayName ?: "사용자", fontWeight = FontWeight.Bold, color = theme.textPrimary)
                    Text(workspace?.name ?: "", fontSize = 14.sp, color = theme.textSecondary)
                }
            }
        }

        Spacer(Modifier.height(20.dp))
        Text("테마", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = theme.textSecondary)
        Spacer(Modifier.height(8.dp))

        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = theme.cardBackground)
        ) {
            Column {
                AppThemeType.entries.forEach { themeType ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { scope.launch { themeManager.setTheme(themeType) } }
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(themeType.displayName, color = theme.textPrimary, modifier = Modifier.weight(1f))
                        if (theme.type == themeType) {
                            Icon(Icons.Default.Check, null, tint = theme.primary)
                        }
                    }
                    if (themeType != AppThemeType.entries.last()) {
                        HorizontalDivider(color = theme.divider, modifier = Modifier.padding(horizontal = 16.dp))
                    }
                }
            }
        }

        Spacer(Modifier.height(20.dp))

        // Logout
        OutlinedButton(
            onClick = { scope.launch { authManager.signOut() } },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
        ) {
            Icon(Icons.Default.Logout, null, tint = theme.danger)
            Spacer(Modifier.width(8.dp))
            Text("로그아웃", color = theme.danger)
        }

        Spacer(Modifier.height(16.dp))

        // Delete Account
        var showDeleteDialog by remember { mutableStateOf(false) }
        var isDeleting by remember { mutableStateOf(false) }

        TextButton(
            onClick = { showDeleteDialog = true },
            enabled = !isDeleting,
            modifier = Modifier.fillMaxWidth()
        ) {
            if (isDeleting) {
                CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                Spacer(Modifier.width(8.dp))
            }
            Text("계정 탈퇴", fontSize = 13.sp, color = theme.textSecondary)
        }

        if (showDeleteDialog) {
            AlertDialog(
                onDismissRequest = { showDeleteDialog = false },
                title = { Text("계정 탈퇴") },
                text = { Text("계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다. 정말 탈퇴하시겠습니까?") },
                confirmButton = {
                    TextButton(onClick = {
                        showDeleteDialog = false
                        isDeleting = true
                        scope.launch {
                            authManager.deleteAccount()
                            isDeleting = false
                        }
                    }) {
                        Text("탈퇴하기", color = theme.danger)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showDeleteDialog = false }) {
                        Text("취소")
                    }
                }
            )
        }

        Spacer(Modifier.height(32.dp))
        Text("Influe v1.0", fontSize = 12.sp, color = theme.textSecondary, modifier = Modifier.align(Alignment.CenterHorizontally))
    }
}

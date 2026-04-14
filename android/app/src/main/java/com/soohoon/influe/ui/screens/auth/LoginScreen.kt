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
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.ui.theme.LocalAppTheme
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(authManager: AuthManager) {
    val theme = LocalAppTheme.current
    val scope = rememberCoroutineScope()
    val isLoading by authManager.isLoading.collectAsState()
    val errorMessage by authManager.errorMessage.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.linearGradient(theme.gradient)),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                "Influe",
                fontSize = 42.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "인플루언서를 위한 협찬 관리",
                fontSize = 16.sp,
                color = Color.White.copy(alpha = 0.85f)
            )
            Spacer(Modifier.height(48.dp))

            Button(
                onClick = { scope.launch { authManager.signInWithGoogle() } },
                modifier = Modifier.fillMaxWidth(0.8f).height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.White),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                } else {
                    Text("Google로 로그인", color = Color(0xFF333333), fontWeight = FontWeight.SemiBold)
                }
            }

            errorMessage?.let { msg ->
                Spacer(Modifier.height(16.dp))
                Text(msg, color = Color.White.copy(alpha = 0.9f), fontSize = 14.sp)
            }
        }
    }
}

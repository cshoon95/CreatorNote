package com.soohoon.influe

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import androidx.lifecycle.lifecycleScope
import com.soohoon.influe.data.repository.DataRepository
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.data.supabase.WorkspaceManager
import com.soohoon.influe.ui.navigation.AppNavigation
import com.soohoon.influe.ui.theme.LocalAppTheme
import com.soohoon.influe.ui.theme.ThemeManager
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private lateinit var authManager: AuthManager
    private lateinit var workspaceManager: WorkspaceManager
    private lateinit var dataRepository: DataRepository
    private lateinit var themeManager: ThemeManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        authManager = AuthManager(this)
        workspaceManager = WorkspaceManager(authManager)
        dataRepository = DataRepository(this, authManager, workspaceManager)
        themeManager = ThemeManager(this)

        lifecycleScope.launch {
            themeManager.loadTheme()
            authManager.checkSession()
        }

        setContent {
            val theme by themeManager.theme

            LaunchedEffect(theme.isDark) {
                enableEdgeToEdge(
                    statusBarStyle = if (theme.isDark) SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
                        else SystemBarStyle.light(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT),
                    navigationBarStyle = if (theme.isDark) SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
                        else SystemBarStyle.light(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT)
                )
            }

            CompositionLocalProvider(LocalAppTheme provides theme) {
                AppNavigation(
                    authManager = authManager,
                    workspaceManager = workspaceManager,
                    dataRepository = dataRepository,
                    themeManager = themeManager
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.data?.let { uri ->
            if (uri.scheme == "influe" && uri.host == "auth") {
                lifecycleScope.launch {
                    authManager.handleAuthCallback(uri.toString())
                    workspaceManager.fetchWorkspaces()
                    dataRepository.fetchAll()
                }
            }
        }
    }
}

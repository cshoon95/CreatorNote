package com.soohoon.influe.ui.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.*
import com.soohoon.influe.data.repository.DataRepository
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.data.supabase.WorkspaceManager
import com.soohoon.influe.ui.screens.auth.LoginScreen
import com.soohoon.influe.ui.screens.auth.WorkspaceSetupScreen
import com.soohoon.influe.ui.screens.calendar.CalendarScreen
import com.soohoon.influe.ui.screens.dashboard.DashboardScreen
import com.soohoon.influe.ui.screens.notes.NotesScreen
import com.soohoon.influe.ui.screens.settlement.SettlementListScreen
import com.soohoon.influe.ui.screens.settings.SettingsScreen
import com.soohoon.influe.ui.screens.sponsorship.SponsorshipListScreen
import com.soohoon.influe.ui.theme.LocalAppTheme
import com.soohoon.influe.ui.theme.ThemeManager

enum class BottomTab(val route: String, val label: String, val icon: ImageVector) {
    HOME("home", "홈", Icons.Default.Home),
    SPONSORSHIP("sponsorship", "협찬", Icons.Default.CardGiftcard),
    SETTLEMENT("settlement", "정산", Icons.Default.AccountBalanceWallet),
    CALENDAR("calendar", "캘린더", Icons.Default.CalendarMonth),
    NOTES("notes", "노트", Icons.Default.EditNote)
}

@Composable
fun AppNavigation(
    authManager: AuthManager,
    workspaceManager: WorkspaceManager,
    dataRepository: DataRepository,
    themeManager: ThemeManager
) {
    val isAuthenticated by authManager.isAuthenticated.collectAsState()
    val isLoading by authManager.isLoading.collectAsState()
    val currentWorkspace by workspaceManager.currentWorkspace.collectAsState()
    val theme = LocalAppTheme.current

    if (isLoading) {
        Box(Modifier.fillMaxSize()) {}
        return
    }

    if (!isAuthenticated) {
        LoginScreen(authManager = authManager)
        return
    }

    if (currentWorkspace == null) {
        WorkspaceSetupScreen(workspaceManager = workspaceManager)
        return
    }

    // Main app with bottom nav
    val navController = rememberNavController()

    LaunchedEffect(currentWorkspace?.id) {
        if (currentWorkspace != null) dataRepository.fetchAll()
    }

    Scaffold(
        containerColor = theme.background,
        bottomBar = {
            NavigationBar(
                containerColor = theme.cardBackground,
                contentColor = theme.textPrimary
            ) {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination

                BottomTab.entries.forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label, style = MaterialTheme.typography.labelSmall) },
                        selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = theme.primary,
                            selectedTextColor = theme.primary,
                            unselectedIconColor = theme.textSecondary,
                            unselectedTextColor = theme.textSecondary,
                            indicatorColor = theme.primary.copy(alpha = 0.1f)
                        )
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = BottomTab.HOME.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(BottomTab.HOME.route) {
                DashboardScreen(
                    dataRepository = dataRepository,
                    themeManager = themeManager,
                    authManager = authManager,
                    onSettingsClick = { navController.navigate("settings") }
                )
            }
            composable(BottomTab.SPONSORSHIP.route) {
                SponsorshipListScreen(dataRepository = dataRepository, authManager = authManager, workspaceManager = workspaceManager)
            }
            composable(BottomTab.SETTLEMENT.route) {
                SettlementListScreen(dataRepository = dataRepository, authManager = authManager, workspaceManager = workspaceManager)
            }
            composable(BottomTab.CALENDAR.route) {
                CalendarScreen(dataRepository = dataRepository)
            }
            composable(BottomTab.NOTES.route) {
                NotesScreen(dataRepository = dataRepository, authManager = authManager, workspaceManager = workspaceManager)
            }
            composable("settings") {
                SettingsScreen(authManager = authManager, workspaceManager = workspaceManager, themeManager = themeManager)
            }
        }
    }
}

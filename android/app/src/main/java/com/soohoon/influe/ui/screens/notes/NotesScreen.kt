package com.soohoon.influe.ui.screens.notes

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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.model.ReelsNoteDTO
import com.soohoon.influe.data.model.GeneralNoteDTO
import com.soohoon.influe.data.repository.DataRepository
import com.soohoon.influe.data.supabase.AuthManager
import com.soohoon.influe.data.supabase.WorkspaceManager
import com.soohoon.influe.ui.components.ReelsNoteStatusBadge
import com.soohoon.influe.ui.components.reelsNoteStatusColor
import com.soohoon.influe.ui.theme.LocalAppTheme
import kotlinx.coroutines.launch

@Composable
fun NotesScreen(
    dataRepository: DataRepository,
    authManager: AuthManager,
    workspaceManager: WorkspaceManager
) {
    val theme = LocalAppTheme.current
    val scope = rememberCoroutineScope()
    var selectedTab by remember { mutableIntStateOf(0) }
    val reelsNotes by dataRepository.reelsNotes.collectAsState()
    val generalNotes by dataRepository.generalNotes.collectAsState()
    var searchText by remember { mutableStateOf("") }

    var showReelsEditor by remember { mutableStateOf(false) }
    var showGeneralEditor by remember { mutableStateOf(false) }
    var editingReelsNote by remember { mutableStateOf<ReelsNoteDTO?>(null) }
    var editingGeneralNote by remember { mutableStateOf<GeneralNoteDTO?>(null) }

    val wsId = workspaceManager.currentWorkspaceId ?: ""
    val userId = authManager.currentUserId ?: ""

    Scaffold(
        containerColor = theme.background,
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    when (selectedTab) {
                        0 -> { editingReelsNote = null; showReelsEditor = true }
                        1 -> { editingGeneralNote = null; showGeneralEditor = true }
                    }
                },
                shape = CircleShape,
                containerColor = theme.cardBackground,
                contentColor = theme.primary
            ) { Icon(Icons.Default.Add, "추가") }
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = theme.background,
                contentColor = theme.primary
            ) {
                Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }) {
                    Text(
                        "릴스 노트",
                        modifier = Modifier.padding(12.dp),
                        fontWeight = if (selectedTab == 0) FontWeight.Bold else FontWeight.Normal
                    )
                }
                Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }) {
                    Text(
                        "메모",
                        modifier = Modifier.padding(12.dp),
                        fontWeight = if (selectedTab == 1) FontWeight.Bold else FontWeight.Normal
                    )
                }
            }

            OutlinedTextField(
                value = searchText,
                onValueChange = { searchText = it },
                placeholder = { Text("노트 검색") },
                leadingIcon = { Icon(Icons.Default.Search, null, tint = theme.textSecondary) },
                trailingIcon = {
                    if (searchText.isNotEmpty()) {
                        Icon(
                            Icons.Default.Clear, null,
                            tint = theme.textSecondary,
                            modifier = Modifier.clickable(interactionSource = null, indication = null) {
                                searchText = ""
                            }
                        )
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )

            when (selectedTab) {
                0 -> {
                    val filtered = remember(reelsNotes, searchText) {
                        reelsNotes.filter {
                            searchText.isEmpty() ||
                                it.title.contains(searchText, true) ||
                                it.plainContent.contains(searchText, true)
                        }
                    }
                    ReelsNoteList(
                        notes = filtered,
                        onNoteClick = { note ->
                            editingReelsNote = note
                            showReelsEditor = true
                        },
                        onDelete = { id ->
                            scope.launch { dataRepository.deleteReelsNote(id) }
                        }
                    )
                }
                1 -> {
                    val filtered = remember(generalNotes, searchText) {
                        generalNotes.filter {
                            searchText.isEmpty() ||
                                it.title.contains(searchText, true) ||
                                it.plainContent.contains(searchText, true)
                        }
                    }
                    GeneralNoteList(
                        notes = filtered,
                        onNoteClick = { note ->
                            editingGeneralNote = note
                            showGeneralEditor = true
                        },
                        onDelete = { id ->
                            scope.launch { dataRepository.deleteGeneralNote(id) }
                        }
                    )
                }
            }
        }
    }

    if (showReelsEditor) {
        ReelsNoteEditorSheet(
            workspaceId = wsId,
            userId = userId,
            note = editingReelsNote,
            onDismiss = { showReelsEditor = false },
            onSave = { insert ->
                scope.launch {
                    dataRepository.createReelsNote(insert)
                    showReelsEditor = false
                }
            },
            onUpdate = { updated ->
                scope.launch {
                    dataRepository.updateReelsNote(updated)
                    showReelsEditor = false
                }
            }
        )
    }

    if (showGeneralEditor) {
        GeneralNoteEditorSheet(
            workspaceId = wsId,
            userId = userId,
            note = editingGeneralNote,
            onDismiss = { showGeneralEditor = false },
            onSave = { insert ->
                scope.launch {
                    dataRepository.createGeneralNote(insert)
                    showGeneralEditor = false
                }
            },
            onUpdate = { updated ->
                scope.launch {
                    dataRepository.updateGeneralNote(updated)
                    showGeneralEditor = false
                }
            }
        )
    }
}

@Composable
fun ReelsNoteList(
    notes: List<ReelsNoteDTO>,
    onNoteClick: (ReelsNoteDTO) -> Unit = {},
    onDelete: (String) -> Unit = {}
) {
    val theme = LocalAppTheme.current
    val sorted = remember(notes) {
        notes.sortedWith(compareByDescending<ReelsNoteDTO> { it.isPinned }.thenByDescending { it.updatedAt })
    }

    if (sorted.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("릴스 노트가 없습니다", color = theme.textSecondary)
        }
        return
    }

    LazyColumn(
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        items(sorted, key = { it.id }) { note ->
            var showDeleteDialog by remember { mutableStateOf(false) }
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = theme.cardBackground),
                modifier = Modifier.clickable { onNoteClick(note) }
            ) {
                Row(modifier = Modifier.padding(0.dp)) {
                    Box(
                        modifier = Modifier
                            .width(4.dp)
                            .fillMaxHeight()
                            .padding(vertical = 6.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(reelsNoteStatusColor(note.reelsNoteStatus))
                    )
                    Column(modifier = Modifier.padding(14.dp).weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (note.isPinned) {
                                Icon(Icons.Default.PushPin, null, tint = theme.primary, modifier = Modifier.size(14.dp))
                                Spacer(Modifier.width(4.dp))
                            }
                            Text(
                                note.title.ifEmpty { "제목 없음" },
                                fontWeight = FontWeight.Bold, fontSize = 14.sp, color = theme.textPrimary,
                                maxLines = 1,
                                modifier = Modifier.weight(1f)
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
                        if (note.plainContent.isNotEmpty()) {
                            Spacer(Modifier.height(4.dp))
                            Text(note.plainContent, fontSize = 12.sp, color = theme.textSecondary, maxLines = 2)
                        }
                        if (note.tags.isNotEmpty()) {
                            Spacer(Modifier.height(4.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                note.tags.take(3).forEach { tag ->
                                    Text("#$tag", fontSize = 11.sp, color = theme.textSecondary)
                                }
                            }
                        }
                        Spacer(Modifier.height(6.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                note.updatedAt.take(16).replace("T", " "),
                                fontSize = 11.sp,
                                color = theme.textSecondary.copy(alpha = 0.7f)
                            )
                            Spacer(Modifier.weight(1f))
                            ReelsNoteStatusBadge(note.reelsNoteStatus)
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
                            onDelete(note.id)
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

@Composable
fun GeneralNoteList(
    notes: List<GeneralNoteDTO>,
    onNoteClick: (GeneralNoteDTO) -> Unit = {},
    onDelete: (String) -> Unit = {}
) {
    val theme = LocalAppTheme.current
    val sorted = remember(notes) {
        notes.sortedWith(compareByDescending<GeneralNoteDTO> { it.isPinned }.thenByDescending { it.updatedAt })
    }

    if (sorted.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("메모가 없습니다", color = theme.textSecondary)
        }
        return
    }

    LazyColumn(
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        items(sorted, key = { it.id }) { note ->
            var showDeleteDialog by remember { mutableStateOf(false) }
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = theme.cardBackground),
                modifier = Modifier.clickable { onNoteClick(note) }
            ) {
                Row(modifier = Modifier.padding(0.dp)) {
                    Box(
                        modifier = Modifier
                            .width(4.dp)
                            .fillMaxHeight()
                            .padding(vertical = 4.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(theme.primary)
                    )
                    Column(modifier = Modifier.padding(14.dp).weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (note.isPinned) {
                                Icon(Icons.Default.PushPin, null, tint = theme.primary, modifier = Modifier.size(14.dp))
                                Spacer(Modifier.width(4.dp))
                            }
                            Text(
                                note.title.ifEmpty { "제목 없음" },
                                fontWeight = FontWeight.Bold, fontSize = 14.sp, color = theme.textPrimary,
                                maxLines = 1,
                                modifier = Modifier.weight(1f)
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
                        if (note.plainContent.isNotEmpty()) {
                            Spacer(Modifier.height(4.dp))
                            Text(note.plainContent, fontSize = 12.sp, color = theme.textSecondary, maxLines = 2)
                        }
                        Spacer(Modifier.height(6.dp))
                        Text(
                            note.updatedAt.take(16).replace("T", " "),
                            fontSize = 11.sp,
                            color = theme.textSecondary.copy(alpha = 0.7f)
                        )
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
                            onDelete(note.id)
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

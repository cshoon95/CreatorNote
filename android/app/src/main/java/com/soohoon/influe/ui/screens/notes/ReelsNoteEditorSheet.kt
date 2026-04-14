package com.soohoon.influe.ui.screens.notes

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.FormatListBulleted
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.model.ReelsNoteDTO
import com.soohoon.influe.data.model.ReelsNoteInsert
import com.soohoon.influe.data.model.ReelsNoteStatus
import com.soohoon.influe.ui.theme.LocalAppTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReelsNoteEditorSheet(
    workspaceId: String,
    userId: String,
    note: ReelsNoteDTO? = null,
    onDismiss: () -> Unit,
    onSave: (ReelsNoteInsert) -> Unit,
    onUpdate: ((ReelsNoteDTO) -> Unit)? = null
) {
    val theme = LocalAppTheme.current
    var title by remember { mutableStateOf(note?.title ?: "") }
    var content by remember { mutableStateOf(note?.plainContent ?: "") }
    var statusValue by remember { mutableStateOf(note?.status ?: "drafting") }
    var tagsText by remember { mutableStateOf(note?.tags?.joinToString(", ") ?: "") }

    var isBold by remember { mutableStateOf(false) }
    var isItalic by remember { mutableStateOf(false) }
    var isUnderline by remember { mutableStateOf(false) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = theme.cardBackground
    ) {
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                if (note == null) "릴스 노트 작성" else "릴스 노트 편집",
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = theme.textPrimary
            )
            Spacer(Modifier.height(16.dp))

            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("제목") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )
            Spacer(Modifier.height(12.dp))

            OutlinedTextField(
                value = content,
                onValueChange = { content = it },
                label = { Text("내용") },
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 160.dp),
                shape = RoundedCornerShape(12.dp),
                minLines = 6
            )
            Spacer(Modifier.height(8.dp))

            // Formatting toolbar - horizontally scrollable with proper padding
            FormattingToolbar(
                isBold = isBold,
                isItalic = isItalic,
                isUnderline = isUnderline,
                onBoldClick = { isBold = !isBold },
                onItalicClick = { isItalic = !isItalic },
                onUnderlineClick = { isUnderline = !isUnderline }
            )

            Spacer(Modifier.height(16.dp))

            Text("상태", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = theme.textSecondary)
            Spacer(Modifier.height(8.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                ReelsNoteStatus.entries.forEach { s ->
                    val isSelected = statusValue == s.rawValue
                    Surface(
                        modifier = Modifier
                            .clip(RoundedCornerShape(20.dp))
                            .clickable(interactionSource = null, indication = null) {
                                statusValue = s.rawValue
                            },
                        shape = RoundedCornerShape(20.dp),
                        color = if (isSelected) theme.primary.copy(alpha = 0.15f) else theme.surfaceBackground,
                        contentColor = if (isSelected) theme.primary else theme.textSecondary
                    ) {
                        Text(
                            s.displayName,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                            fontSize = 13.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                }
            }

            Spacer(Modifier.height(16.dp))

            OutlinedTextField(
                value = tagsText,
                onValueChange = { tagsText = it },
                label = { Text("태그 (쉼표로 구분)") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )

            Spacer(Modifier.height(24.dp))

            Button(
                onClick = {
                    val tags = tagsText.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                    if (note != null && onUpdate != null) {
                        onUpdate(note.copy(
                            title = title.trim(),
                            plainContent = content.trim(),
                            status = statusValue,
                            tags = tags
                        ))
                    } else {
                        onSave(ReelsNoteInsert(
                            workspaceId = workspaceId,
                            createdBy = userId,
                            title = title.trim(),
                            plainContent = content.trim(),
                            status = statusValue,
                            tags = tags
                        ))
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(12.dp),
                enabled = title.isNotBlank() || content.isNotBlank(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = theme.primary,
                    contentColor = androidx.compose.ui.graphics.Color.White
                )
            ) {
                Text("저장", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
fun FormattingToolbar(
    isBold: Boolean,
    isItalic: Boolean,
    isUnderline: Boolean,
    onBoldClick: () -> Unit,
    onItalicClick: () -> Unit,
    onUnderlineClick: () -> Unit
) {
    val theme = LocalAppTheme.current

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .background(theme.surfaceBackground, RoundedCornerShape(10.dp))
            .padding(horizontal = 12.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        FormatButton(Icons.Default.FormatBold, "굵게", isBold, onBoldClick)
        FormatButton(Icons.Default.FormatItalic, "기울임", isItalic, onItalicClick)
        FormatButton(Icons.Default.FormatUnderlined, "밑줄", isUnderline, onUnderlineClick)

        Spacer(Modifier.width(4.dp))
        Box(
            Modifier
                .width(1.dp)
                .height(24.dp)
                .background(theme.divider)
        )
        Spacer(Modifier.width(4.dp))

        FormatButton(Icons.Default.FormatStrikethrough, "취소선", false) {}
        FormatButton(Icons.AutoMirrored.Filled.FormatListBulleted, "목록", false) {}
        FormatButton(Icons.Default.Title, "제목", false) {}
        FormatButton(Icons.Default.Link, "링크", false) {}
        FormatButton(Icons.Default.FormatQuote, "인용", false) {}
        FormatButton(Icons.Default.Code, "코드", false) {}
    }
}

@Composable
private fun FormatButton(
    icon: ImageVector,
    description: String,
    isActive: Boolean,
    onClick: () -> Unit
) {
    val theme = LocalAppTheme.current

    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(RoundedCornerShape(8.dp))
            .then(
                if (isActive) Modifier.background(theme.primary.copy(alpha = 0.15f))
                else Modifier
            )
            .clickable(interactionSource = null, indication = null) { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Icon(
            icon, description,
            tint = if (isActive) theme.primary else theme.textSecondary,
            modifier = Modifier.size(20.dp)
        )
    }
}

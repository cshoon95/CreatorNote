package com.soohoon.influe.ui.screens.notes

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.soohoon.influe.data.model.GeneralNoteDTO
import com.soohoon.influe.data.model.GeneralNoteInsert
import com.soohoon.influe.ui.theme.LocalAppTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GeneralNoteEditorSheet(
    workspaceId: String,
    userId: String,
    note: GeneralNoteDTO? = null,
    onDismiss: () -> Unit,
    onSave: (GeneralNoteInsert) -> Unit,
    onUpdate: ((GeneralNoteDTO) -> Unit)? = null
) {
    val theme = LocalAppTheme.current
    var title by remember { mutableStateOf(note?.title ?: "") }
    var content by remember { mutableStateOf(note?.plainContent ?: "") }
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
                if (note == null) "메모 작성" else "메모 편집",
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

            FormattingToolbar(
                isBold = isBold,
                isItalic = isItalic,
                isUnderline = isUnderline,
                onBoldClick = { isBold = !isBold },
                onItalicClick = { isItalic = !isItalic },
                onUnderlineClick = { isUnderline = !isUnderline }
            )

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
                            tags = tags
                        ))
                    } else {
                        onSave(GeneralNoteInsert(
                            workspaceId = workspaceId,
                            createdBy = userId,
                            title = title.trim(),
                            plainContent = content.trim(),
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

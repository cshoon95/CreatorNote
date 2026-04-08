import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 24) {
                // Profile section
                VStack(alignment: .leading, spacing: 16) {
                    Text("계정")
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)

                    if let profile = AuthManager.shared.currentProfile {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Text(String((profile.displayName ?? "U").prefix(1)))
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.displayName ?? "사용자")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(theme.textPrimary)
                                if let provider = profile.provider {
                                    Text(provider)
                                        .font(.caption)
                                        .foregroundStyle(theme.textSecondary)
                                }
                            }
                            Spacer()
                        }
                    }

                    NavigationLink("워크스페이스") {
                        WorkspaceSettingsView()
                    }
                    .foregroundStyle(theme.primary)

                    Button("로그아웃") {
                        Task { await AuthManager.shared.signOut() }
                    }
                    .foregroundStyle(.red)
                }
                .padding()
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Theme selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("테마 선택")
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(AppThemeType.allCases) { themeType in
                            let t = AppTheme.theme(for: themeType)
                            let isSelected = themeManager.currentThemeType == themeType

                            Button {
                                themeManager.setTheme(themeType)
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: t.gradient,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(height: 80)

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white)
                                        } else {
                                            Image(systemName: themeType.icon)
                                                .font(.title3)
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 3)
                                    )

                                    Text(themeType.displayName)
                                        .font(.caption.bold())
                                        .foregroundStyle(isSelected ? theme.primary : theme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("미리보기")
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)

                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Text("A")
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                    }
                                VStack(alignment: .leading) {
                                    Text("브랜드 예시")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(theme.textPrimary)
                                    Text("제품 설명 미리보기")
                                        .font(.caption)
                                        .foregroundStyle(theme.textSecondary)
                                }
                                Spacer()
                                Text("D-14")
                                    .font(.caption.bold())
                                    .foregroundStyle(theme.primary)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(ReelsNoteStatus.allCases, id: \.self) { status in
                            StatusBadge(status: status)
                        }
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // App info
                VStack(spacing: 8) {
                    Text("Creator Note")
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)
                    Text("인플루언서를 위한 올인원 관리 앱")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                    Text("v1.0.0")
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary.opacity(0.6))
                }
                .padding()
            }
            .padding()
        }
        .background(theme.background)
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

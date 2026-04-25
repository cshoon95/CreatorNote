import SwiftUI

struct ThemeSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                // 시스템 설정 따라가기
                Button {
                    themeManager.toggleFollowSystem()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: themeManager.followSystem ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(themeManager.followSystem ? theme.primary : theme.textSecondary)
                        Text("시스템 설정 따라가기")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                    }
                    .padding(16)
                    .background(themeManager.followSystem ? theme.primary.opacity(0.08) : theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(themeManager.followSystem ? theme.primary.opacity(0.3) : theme.divider, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // 테마 그리드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                    ForEach(AppThemeType.allCases) { themeType in
                        let t = AppTheme.theme(for: themeType)
                        let isSelected = themeManager.currentThemeType == themeType

                        Button {
                            themeManager.setTheme(themeType)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(t.primary)
                                        .frame(height: 96)

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : themeType.icon)
                                        .font(.system(size: isSelected ? 26 : 22, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(.white.opacity(isSelected ? 1 : 0.85))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 3)
                                )
                                .shadow(
                                    color: isSelected ? t.primary.opacity(0.4) : .black.opacity(0.06),
                                    radius: isSelected ? 10 : 4,
                                    y: isSelected ? 4 : 2
                                )

                                Text(themeType.displayName)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(isSelected ? theme.primary : theme.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(theme.surfaceBackground.ignoresSafeArea())
        .navigationTitle("테마 설정")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(themeManager.resolvedColorScheme)
    }
}

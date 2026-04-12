import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                profileHeroCard(theme: theme)
                workspaceCard(theme: theme)
                themeCard(theme: theme)
                appInfoCard(theme: theme)
                logoutButton(theme: theme)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(theme.surfaceBackground.ignoresSafeArea())
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(theme.colorScheme)
    }

    private func profileHeroCard(theme: AppTheme) -> some View {
        ZStack {
            LinearGradient(
                colors: theme.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 70, height: 70)

                    if let profile = AuthManager.shared.currentProfile {
                        Text(String((profile.displayName ?? "U").prefix(1)).uppercased())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 6) {
                    if let profile = AuthManager.shared.currentProfile {
                        Text(profile.displayName ?? "사용자")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if let provider = profile.provider {
                            HStack(spacing: 5) {
                                Image(systemName: provider.lowercased() == "apple" ? "apple.logo" : "globe")
                                    .font(.caption)
                                Text(provider)
                                    .font(.system(.subheadline, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.8))
                        }
                    } else {
                        Text("로그인되지 않음")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .shadow(color: theme.gradient.first?.opacity(0.35) ?? .clear, radius: 16, x: 0, y: 8)
    }

    private func workspaceCard(theme: AppTheme) -> some View {
        NavigationLink {
            WorkspaceSettingsView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: theme.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "rectangle.3.group.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("워크스페이스 관리")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.textPrimary)

                    Text("팀 공간 설정 및 구성원 관리")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func themeCard(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Text("테마 선택")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.textPrimary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                ForEach(AppThemeType.allCases) { themeType in
                    let t = AppTheme.theme(for: themeType)
                    let isSelected = themeManager.currentThemeType == themeType

                    Button {
                        themeManager.setTheme(themeType)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: t.gradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 90)

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Image(systemName: themeType.icon)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        isSelected ? theme.primary : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(
                                color: isSelected ? (t.gradient.first?.opacity(0.4) ?? .clear) : .black.opacity(0.06),
                                radius: isSelected ? 10 : 4,
                                x: 0,
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
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func appInfoCard(theme: AppTheme) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: theme.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: theme.gradient.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Influe")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(theme.textPrimary)

                Text("인플루언서를 위한 스마트 관리")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Text("v1.0.0")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(theme.textSecondary.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.surfaceBackground)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func logoutButton(theme: AppTheme) -> some View {
        Button {
            Task { await AuthManager.shared.signOut() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .semibold))

                Text("로그아웃")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF4B4B"), Color(hex: "FF2D55")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(hex: "FF2D55").opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .padding(.bottom, 8)
    }
}

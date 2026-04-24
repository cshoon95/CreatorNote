import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var showLogoutConfirmation = false

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                profileHeroCard(theme: theme)
                workspaceCard(theme: theme)
                themeCard(theme: theme)
                logoutButton(theme: theme)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(theme.surfaceBackground.ignoresSafeArea())
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(themeManager.resolvedColorScheme)
        .confirmationDialog("로그아웃", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) {
                Task { await AuthManager.shared.signOut() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
    }

    private func profileHeroCard(theme: AppTheme) -> some View {
        NavigationLink {
            ProfileView()
        } label: {
            ZStack {
                theme.primary
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                HStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 80, height: 80)

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
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
            .contentShape(Rectangle())
            .shadow(color: theme.primary.opacity(0.25), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func workspaceCard(theme: AppTheme) -> some View {
        NavigationLink {
            WorkspaceSettingsView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primary)
                        .frame(width: 48, height: 48)

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
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
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
                .padding(12)
                .background(themeManager.followSystem ? theme.primary.opacity(0.08) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 14) {
                ForEach(AppThemeType.allCases) { themeType in
                    let t = AppTheme.theme(for: themeType)
                    let isSelected = themeManager.currentThemeType == themeType

                    Button {
                        themeManager.setTheme(themeType)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(
                                        t.primary
                                    )
                                    .frame(height: 96)

                                Image(systemName: isSelected ? "checkmark.circle.fill" : themeType.icon)
                                    .font(.system(size: isSelected ? 26 : 22, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(.white.opacity(isSelected ? 1 : 0.85))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        isSelected ? theme.primary : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(
                                color: isSelected ? t.primary.opacity(0.4) : .black.opacity(0.06),
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
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func appInfoCard(theme: AppTheme) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(theme.primary)
                    .frame(width: 56, height: 56)

                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 3)

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

            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
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
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func logoutButton(theme: AppTheme) -> some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("로그아웃")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .padding(.bottom, 12)
    }
}

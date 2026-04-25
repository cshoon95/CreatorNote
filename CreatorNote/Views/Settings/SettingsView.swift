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
                helpCard(theme: theme)
                logoutButton(theme: theme)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
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
        NavigationLink {
            ThemeSettingsView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.primary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("테마 설정")
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundStyle(theme.textPrimary)
                    Text(themeManager.currentThemeType.displayName)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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

    private func helpCard(theme: AppTheme) -> some View {
        NavigationLink {
            HelpView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primary)
                        .frame(width: 48, height: 48)
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("도움말")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.textPrimary)
                    Text("각 화면 기능 안내")
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
            .background(Color.red.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.red.opacity(0.25), lineWidth: 1)
            )
        }
        .padding(.bottom, 12)
    }
}

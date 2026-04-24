import SwiftUI

struct SponsorshipDetailView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    let sponsorshipId: UUID

    // DataManager가 @Observable이므로 sponsorships 변경 시 자동 갱신
    private var sponsorship: SponsorshipDTO? {
        DataManager.shared.sponsorships.first { $0.id == sponsorshipId }
    }

    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    var body: some View {
        let theme = themeManager.theme
        Group {
            if let sponsorship {
                detailContent(sponsorship: sponsorship, theme: theme)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(theme.textSecondary)
                    Text("삭제된 협찬입니다")
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.background)
            }
        }
        .navigationTitle(sponsorship?.brandName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(theme.colorScheme)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("편집") { isEditing = true }
                    Divider()
                    Button("삭제", role: .destructive) { showDeleteConfirm = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(theme.primary)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let sponsorship {
                SponsorshipFormView(editingSponsorship: sponsorship)
            }
        }
        .confirmationDialog("협찬을 삭제하시겠습니까?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                Task {
                    await DataManager.shared.deleteSponsorship(id: sponsorshipId)
                    dismiss()
                }
            }
            Button("취소", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func detailContent(sponsorship: SponsorshipDTO, theme: AppTheme) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // 헤더 카드
                ThemedCard {
                    VStack(spacing: 16) {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Text(String(sponsorship.brandName.prefix(1)))
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sponsorship.brandName)
                                    .font(.title3.bold())
                                    .foregroundStyle(theme.textPrimary)
                                if !sponsorship.productName.isEmpty {
                                    Text(sponsorship.productName)
                                        .font(.subheadline)
                                        .foregroundStyle(theme.textSecondary)
                                }
                            }
                            Spacer()
                            SponsorshipStatusBadge(status: sponsorship.sponsorshipStatus)
                        }

                        Divider()
                            .background(theme.textSecondary.opacity(0.2))

                        infoRow(icon: "wonsign.circle", label: "금액", theme: theme) {
                            Text(sponsorship.amount.krwFormatted)
                                .font(.headline.bold())
                                .foregroundStyle(theme.primary)
                        }

                        infoRow(icon: "calendar", label: "기간", theme: theme) {
                            Text("\(formatDate(sponsorship.startDate)) ~ \(formatDate(sponsorship.endDate))")
                                .font(.subheadline)
                                .foregroundStyle(theme.textPrimary)
                        }

                        infoRow(icon: "clock", label: "남은 일수", theme: theme) {
                            Text(sponsorship.isExpired ? "만료됨" : "D-\(sponsorship.daysRemaining)")
                                .font(.headline.bold())
                                .foregroundStyle(sponsorship.isExpired ? .red : (sponsorship.isExpiringSoon ? .orange : theme.primary))
                        }
                    }
                }
                .padding(.horizontal)

                // 상태 변경 카드
                ThemedCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("상태 변경", systemImage: "flag")
                            .font(.subheadline.bold())
                            .foregroundStyle(theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SponsorshipStatus.allCases, id: \.self) { s in
                                    Button {
                                        Haptic.selection()
                                        var updated = sponsorship
                                        updated.status = s.rawValue
                                        Task { await DataManager.shared.updateSponsorship(updated) }
                                    } label: {
                                        SponsorshipStatusBadge(status: s)
                                            .opacity(sponsorship.sponsorshipStatus == s ? 1 : 0.35)
                                            .scaleEffect(sponsorship.sponsorshipStatus == s ? 1.08 : 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.horizontal)

                // 세부 내용
                if !sponsorship.details.isEmpty {
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("세부 내용", systemImage: "doc.text")
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textSecondary)
                            Text(sponsorship.details)
                                .font(.body)
                                .foregroundStyle(theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                }

                // 등록일
                ThemedCard {
                    HStack {
                        Label("등록일", systemImage: "calendar.badge.plus")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                        Spacer()
                        Text(formatDate(sponsorship.createdAt))
                            .font(.subheadline)
                            .foregroundStyle(theme.textPrimary)
                    }
                }
                .padding(.horizontal)

                // 삭제 버튼
                Button {
                    showDeleteConfirm = true
                } label: {
                    Label("협찬 삭제", systemImage: "trash")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
        .background(theme.background)
    }

    @ViewBuilder
    private func infoRow<V: View>(icon: String, label: String, theme: AppTheme, @ViewBuilder value: () -> V) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            Spacer()
            value()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yy.MM.dd"
        return f.string(from: date)
    }
}

import SwiftUI

struct GlobalSearchView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var sponsorships: [SponsorshipDTO] { DataManager.shared.sponsorships }
    private var settlements: [SettlementDTO] { DataManager.shared.settlements }
    private var reelsNotes: [ReelsNoteDTO] { DataManager.shared.reelsNotes }
    private var generalNotes: [GeneralNoteDTO] { DataManager.shared.generalNotes }

    private var filteredSponsorships: [SponsorshipDTO] {
        guard !searchText.isEmpty else { return [] }
        return sponsorships.filter {
            $0.brandName.localizedCaseInsensitiveContains(searchText) ||
            $0.productName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredSettlements: [SettlementDTO] {
        guard !searchText.isEmpty else { return [] }
        return settlements.filter {
            $0.brandName.localizedCaseInsensitiveContains(searchText) ||
            $0.memo.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredReelsNotes: [ReelsNoteDTO] {
        guard !searchText.isEmpty else { return [] }
        return reelsNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.plainContent.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredGeneralNotes: [GeneralNoteDTO] {
        guard !searchText.isEmpty else { return [] }
        return generalNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.plainContent.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var hasResults: Bool {
        !filteredSponsorships.isEmpty || !filteredSettlements.isEmpty ||
        !filteredReelsNotes.isEmpty || !filteredGeneralNotes.isEmpty
    }

    var body: some View {
        let theme = themeManager.theme
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.textSecondary)
                TextField("전체 검색...", text: $searchText)
                    .foregroundStyle(theme.textPrimary)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Haptic.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
            .padding(14)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: theme.primary.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)

            if searchText.isEmpty {
                emptyQueryState(theme: theme)
            } else if !hasResults {
                noResultsState(theme: theme)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if !filteredSponsorships.isEmpty {
                            searchSection(
                                title: "협찬",
                                icon: "gift.fill",
                                color: theme.primary,
                                theme: theme
                            ) {
                                ForEach(filteredSponsorships.prefix(3)) { item in
                                    searchRow(
                                        icon: "gift.fill",
                                        iconColor: theme.primary,
                                        title: item.brandName,
                                        subtitle: item.productName.isEmpty ? nil : item.productName,
                                        theme: theme
                                    )
                                }
                                if filteredSponsorships.count > 3 {
                                    moreButton(count: filteredSponsorships.count - 3, theme: theme)
                                }
                            }
                        }

                        if !filteredSettlements.isEmpty {
                            searchSection(
                                title: "정산",
                                icon: "wonsign.circle.fill",
                                color: theme.accent,
                                theme: theme
                            ) {
                                ForEach(filteredSettlements.prefix(3)) { item in
                                    searchRow(
                                        icon: "wonsign.circle.fill",
                                        iconColor: theme.accent,
                                        title: item.brandName,
                                        subtitle: item.memo.isEmpty ? nil : item.memo,
                                        theme: theme
                                    )
                                }
                                if filteredSettlements.count > 3 {
                                    moreButton(count: filteredSettlements.count - 3, theme: theme)
                                }
                            }
                        }

                        if !filteredReelsNotes.isEmpty {
                            searchSection(
                                title: "릴스 노트",
                                icon: "note.text",
                                color: .orange,
                                theme: theme
                            ) {
                                ForEach(filteredReelsNotes.prefix(3)) { item in
                                    searchRow(
                                        icon: "note.text",
                                        iconColor: .orange,
                                        title: item.title.isEmpty ? "제목 없음" : item.title,
                                        subtitle: item.plainContent.isEmpty ? nil : item.plainContent,
                                        theme: theme
                                    )
                                }
                                if filteredReelsNotes.count > 3 {
                                    moreButton(count: filteredReelsNotes.count - 3, theme: theme)
                                }
                            }
                        }

                        if !filteredGeneralNotes.isEmpty {
                            searchSection(
                                title: "메모",
                                icon: "doc.text.fill",
                                color: .blue,
                                theme: theme
                            ) {
                                ForEach(filteredGeneralNotes.prefix(3)) { item in
                                    searchRow(
                                        icon: "doc.text.fill",
                                        iconColor: .blue,
                                        title: item.title.isEmpty ? "제목 없음" : item.title,
                                        subtitle: item.plainContent.isEmpty ? nil : item.plainContent,
                                        theme: theme
                                    )
                                }
                                if filteredGeneralNotes.count > 3 {
                                    moreButton(count: filteredGeneralNotes.count - 3, theme: theme)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.background)
        .onAppear {
            isSearchFocused = true
        }
    }

    private func searchSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        theme: AppTheme,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.leading, 4)

            ThemedCard {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    private func searchRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
        theme: AppTheme
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(theme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, 6)
    }

    private func moreButton(count: Int, theme: AppTheme) -> some View {
        HStack {
            Spacer()
            Text("+ \(count)개 더보기")
                .font(.caption.bold())
                .foregroundStyle(theme.primary)
                .padding(.vertical, 4)
            Spacer()
        }
    }

    private func emptyQueryState(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(theme.textSecondary.opacity(0.4))
            Text("검색어를 입력하세요")
                .font(.headline)
                .foregroundStyle(theme.textSecondary)
            Text("협찬, 정산, 노트 등을 통합 검색할 수 있어요")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func noResultsState(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(theme.textSecondary.opacity(0.4))
            Text("검색 결과가 없습니다")
                .font(.headline)
                .foregroundStyle(theme.textSecondary)
            Text("'\(searchText)'에 대한 결과를 찾지 못했어요")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

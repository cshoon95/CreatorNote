import SwiftUI

struct HelpView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var expandedItem: String?

    private let sections: [HelpSection] = [
        HelpSection(
            id: "dashboard",
            icon: "square.grid.2x2.fill",
            title: "대시보드",
            subtitle: "협찬 현황을 한눈에",
            items: [
                HelpItem(title: "진행 중인 협찬", description: "현재 진행 중인 협찬 건수와 마감 임박 항목을 한눈에 확인할 수 있습니다."),
                HelpItem(title: "정산 현황", description: "이번 달 예상 수익과 정산 완료 금액을 요약해서 보여줍니다."),
                HelpItem(title: "빠른 접근", description: "최근에 등록한 협찬과 노트에 빠르게 접근할 수 있습니다.")
            ]
        ),
        HelpSection(
            id: "sponsorship",
            icon: "gift.fill",
            title: "협찬 관리",
            subtitle: "협찬 일정과 브랜드를 체계적으로",
            items: [
                HelpItem(title: "협찬 등록", description: "브랜드명, 협찬 유형, 시작일·마감일, 금액을 입력해 협찬을 등록합니다. 우측 상단 + 버튼을 누르세요."),
                HelpItem(title: "상태 관리", description: "협찬 상태를 '진행 예정 → 진행 중 → 업로드 완료 → 정산 완료' 순서로 관리할 수 있습니다."),
                HelpItem(title: "필터 & 정렬", description: "상태별, 날짜별로 협찬 목록을 필터링하고 정렬할 수 있습니다."),
                HelpItem(title: "상세 편집", description: "협찬 항목을 탭하면 상세 정보를 보고 수정할 수 있습니다.")
            ]
        ),
        HelpSection(
            id: "settlement",
            icon: "wonsign.circle.fill",
            title: "정산 추적",
            subtitle: "수익과 세금을 정확하게",
            items: [
                HelpItem(title: "정산 등록", description: "협찬에 연결된 정산 내역을 입력합니다. 세금계산서 발행 여부와 플랫폼 수수료를 함께 기록하세요."),
                HelpItem(title: "자동 계산", description: "수수료율과 세율을 입력하면 실수령액을 자동으로 계산해 줍니다."),
                HelpItem(title: "정산 현황", description: "미정산·정산완료 항목을 구분해서 볼 수 있어 누락을 방지합니다.")
            ]
        ),
        HelpSection(
            id: "calendar",
            icon: "calendar",
            title: "캘린더",
            subtitle: "일정을 시각적으로",
            items: [
                HelpItem(title: "월별 보기", description: "등록된 협찬의 시작일과 마감일을 캘린더에서 한눈에 확인합니다."),
                HelpItem(title: "마감 임박 표시", description: "마감이 가까운 협찬은 강조 표시되어 놓치지 않도록 도와줍니다."),
                HelpItem(title: "날짜 탭", description: "캘린더에서 특정 날짜를 탭하면 해당 날짜의 협찬 목록을 확인할 수 있습니다.")
            ]
        ),
        HelpSection(
            id: "notes",
            icon: "note.text",
            title: "노트",
            subtitle: "대본과 아이디어를 스마트하게",
            items: [
                HelpItem(title: "릴스 노트", description: "릴스·쇼츠 대본을 협찬별로 연결해서 작성할 수 있습니다. 제목, 내용, 캡션, 해시태그를 구분해 관리하세요."),
                HelpItem(title: "일반 노트", description: "아이디어, 메모, 브랜드 피드백 등 자유롭게 기록할 수 있는 노트입니다."),
                HelpItem(title: "태그", description: "노트에 태그를 달아 빠르게 검색하고 분류할 수 있습니다.")
            ]
        ),
        HelpSection(
            id: "workspace",
            icon: "person.2.fill",
            title: "워크스페이스",
            subtitle: "팀과 함께 일하기",
            items: [
                HelpItem(title: "1계정 1워크스페이스", description: "각 계정은 하나의 워크스페이스에만 속할 수 있습니다. 초대를 수락하면 기존 워크스페이스에서 자동으로 나가게 됩니다."),
                HelpItem(title: "초대 코드", description: "방장이 초대 코드를 생성하면 6자리 코드를 팀원에게 공유하세요. 코드는 7일간 유효하며 최대 5회 사용 가능합니다."),
                HelpItem(title: "멤버 승인", description: "초대 코드로 참여 요청이 오면 방장이 승인 또는 거절할 수 있습니다. 승인된 멤버만 워크스페이스 데이터를 볼 수 있습니다."),
                HelpItem(title: "방장 vs 멤버", description: "방장은 워크스페이스 삭제, 멤버 추방, 초대 코드 생성이 가능합니다. 멤버는 워크스페이스에서 나가기만 할 수 있습니다.")
            ]
        ),
        HelpSection(
            id: "settings",
            icon: "gearshape.fill",
            title: "설정",
            subtitle: "내 환경 맞춤 설정",
            items: [
                HelpItem(title: "프로필", description: "닉네임을 변경하거나 계정을 삭제할 수 있습니다. 프로필 카드를 탭하세요."),
                HelpItem(title: "테마", description: "앱의 색상 테마를 변경할 수 있습니다. 시스템 설정을 따라가거나 원하는 색상을 직접 선택하세요."),
                HelpItem(title: "로그아웃", description: "현재 계정에서 로그아웃합니다. 데이터는 서버에 보존되며 다시 로그인하면 복원됩니다.")
            ]
        )
    ]

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 12) {
                ForEach(sections) { section in
                    sectionCard(section: section, theme: theme)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(theme.surfaceBackground.ignoresSafeArea())
        .navigationTitle("도움말")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(themeManager.resolvedColorScheme)
    }

    private func sectionCard(section: HelpSection, theme: AppTheme) -> some View {
        let isExpanded = expandedItem == section.id

        return VStack(spacing: 0) {
            // Header
            Button {
                Haptic.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedItem = isExpanded ? nil : section.id
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primary)
                            .frame(width: 44, height: 44)
                        Image(systemName: section.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(theme.textPrimary)
                        Text(section.subtitle)
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded items
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 6, height: 6)
                                Text(item.title)
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundStyle(theme.textPrimary)
                            }
                            Text(item.description)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 14)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < section.items.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

private struct HelpSection: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let items: [HelpItem]
}

private struct HelpItem {
    let title: String
    let description: String
}

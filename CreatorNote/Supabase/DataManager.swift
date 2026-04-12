import Foundation
@preconcurrency import Supabase

@MainActor @Observable
final class DataManager {
    static let shared = DataManager()

    var sponsorships: [SponsorshipDTO] = []
    var settlements: [SettlementDTO] = []
    var reelsNotes: [ReelsNoteDTO] = []
    var generalNotes: [GeneralNoteDTO] = []
    var isLoading = false
    var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }
    private var workspaceId: UUID? { WorkspaceManager.shared.currentWorkspace?.id }
    private var userId: UUID? { AuthManager.shared.currentUser?.id }

    private init() {}

    private func showError(_ message: String) {
        errorMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            if errorMessage == message { errorMessage = nil }
        }
    }

    func fetchAll() async {
        guard workspaceId != nil else { return }
        isLoading = true
        defer { isLoading = false }
        async let s = fetchSponsorships()
        async let t = fetchSettlements()
        async let r = fetchReelsNotes()
        async let g = fetchGeneralNotes()
        _ = await (s, t, r, g)
    }

    // MARK: - Sponsorships
    func fetchSponsorships() async {
        guard let wid = workspaceId else { return }
        do {
            sponsorships = try await supabase
                .from("sponsorships").select()
                .eq("workspace_id", value: wid.uuidString)
                .order("end_date").execute().value
        } catch { showError("협찬 목록을 불러올 수 없습니다") }
    }

    func createSponsorship(brandName: String, productName: String = "", details: String = "", amount: Double = 0, startDate: Date = .now, endDate: Date = .now.addingTimeInterval(86400 * 30), status: SponsorshipStatus = .preSubmit) async {
        guard let wid = workspaceId, let uid = userId else {
            showError("워크스페이스 또는 로그인 정보가 없습니다")
            return
        }
        do {
            let dto = SponsorshipInsert(workspaceId: wid, createdBy: uid, brandName: brandName, productName: productName, details: details, amount: amount, startDate: startDate, endDate: endDate, status: status.rawValue)
            let created: SponsorshipDTO = try await supabase.from("sponsorships").insert(dto).select().single().execute().value
            sponsorships.insert(created, at: 0)
        } catch {
            showError("협찬 추가 실패: \(error.localizedDescription)")
        }
    }

    func updateSponsorship(_ item: SponsorshipDTO) async {
        let previous = sponsorships.first { $0.id == item.id }
        // Optimistic update
        if let idx = sponsorships.firstIndex(where: { $0.id == item.id }) {
            sponsorships[idx] = item
        }
        do {
            try await supabase.from("sponsorships").update(item).eq("id", value: item.id.uuidString).execute()
            // 정산 대기 → 완료 전환 시 정산 항목 자동 생성
            if previous?.sponsorshipStatus == .pendingSettlement && item.sponsorshipStatus == .completed {
                await createSettlement(
                    brandName: item.brandName,
                    amount: item.amount,
                    settlementDate: Date(),
                    isPaid: false,
                    memo: "협찬 완료 자동 생성",
                    sponsorshipId: item.id
                )
            }
        } catch {
            await fetchSponsorships()
            showError("협찬 수정에 실패했습니다")
        }
    }

    func deleteSponsorship(id: UUID) async {
        let backup = sponsorships
        sponsorships.removeAll { $0.id == id }
        do {
            try await supabase.from("sponsorships").delete().eq("id", value: id.uuidString).execute()
        } catch {
            sponsorships = backup
            showError("삭제에 실패했습니다")
        }
    }

    // MARK: - Settlements
    func fetchSettlements() async {
        guard let wid = workspaceId else { return }
        do {
            settlements = try await supabase
                .from("settlements").select()
                .eq("workspace_id", value: wid.uuidString)
                .order("created_at", ascending: false).execute().value
        } catch { showError("정산 목록을 불러올 수 없습니다") }
    }

    func createSettlement(brandName: String, amount: Double = 0, fee: Double = 0, tax: Double = 0, settlementDate: Date? = nil, isPaid: Bool = false, memo: String = "", sponsorshipId: UUID? = nil) async {
        guard let wid = workspaceId, let uid = userId else { return }
        do {
            let dto = SettlementInsert(workspaceId: wid, createdBy: uid, brandName: brandName, amount: amount, fee: fee, tax: tax, settlementDate: settlementDate, isPaid: isPaid, memo: memo, sponsorshipId: sponsorshipId)
            let created: SettlementDTO = try await supabase.from("settlements").insert(dto).select().single().execute().value
            settlements.insert(created, at: 0)
        } catch { showError("정산 추가에 실패했습니다: \(error.localizedDescription)") }
    }

    func updateSettlement(_ item: SettlementDTO) async {
        // Optimistic update
        if let idx = settlements.firstIndex(where: { $0.id == item.id }) {
            settlements[idx] = item
        }
        do {
            try await supabase.from("settlements").update(item).eq("id", value: item.id.uuidString).execute()
        } catch {
            await fetchSettlements()
            showError("정산 수정에 실패했습니다")
        }
    }

    func deleteSettlement(id: UUID) async {
        let backup = settlements
        settlements.removeAll { $0.id == id }
        do {
            try await supabase.from("settlements").delete().eq("id", value: id.uuidString).execute()
        } catch {
            settlements = backup
            showError("삭제에 실패했습니다")
        }
    }

    // MARK: - Reels Notes
    func fetchReelsNotes() async {
        guard let wid = workspaceId else { return }
        do {
            reelsNotes = try await supabase
                .from("reels_notes").select()
                .eq("workspace_id", value: wid.uuidString)
                .order("updated_at", ascending: false).execute().value
        } catch { showError("릴스 노트를 불러올 수 없습니다") }
    }

    func createReelsNote(title: String = "", plainContent: String = "", status: ReelsNoteStatus = .drafting, tags: [String] = []) async -> ReelsNoteDTO? {
        guard let wid = workspaceId, let uid = userId else { return nil }
        do {
            let dto = ReelsNoteInsert(workspaceId: wid, createdBy: uid, title: title, plainContent: plainContent, status: status.rawValue, tags: tags)
            let created: ReelsNoteDTO = try await supabase
                .from("reels_notes").insert(dto).select().single().execute().value
            reelsNotes.insert(created, at: 0)
            return created
        } catch {
            showError("릴스 노트 추가에 실패했습니다")
            return nil
        }
    }

    func updateReelsNote(_ item: ReelsNoteDTO) async {
        // Optimistic update
        if let idx = reelsNotes.firstIndex(where: { $0.id == item.id }) {
            reelsNotes[idx] = item
        }
        do {
            try await supabase.from("reels_notes").update(item).eq("id", value: item.id.uuidString).execute()
        } catch {
            await fetchReelsNotes()
            showError("릴스 노트 수정에 실패했습니다")
        }
    }

    func deleteReelsNote(id: UUID) async {
        let backup = reelsNotes
        reelsNotes.removeAll { $0.id == id }
        do {
            try await supabase.from("reels_notes").delete().eq("id", value: id.uuidString).execute()
        } catch {
            reelsNotes = backup
            showError("삭제에 실패했습니다")
        }
    }

    // MARK: - General Notes
    func fetchGeneralNotes() async {
        guard let wid = workspaceId else { return }
        do {
            generalNotes = try await supabase
                .from("general_notes").select()
                .eq("workspace_id", value: wid.uuidString)
                .order("updated_at", ascending: false).execute().value
        } catch { showError("메모를 불러올 수 없습니다") }
    }

    func createGeneralNote(title: String = "", plainContent: String = "", tags: [String] = []) async -> GeneralNoteDTO? {
        guard let wid = workspaceId, let uid = userId else { return nil }
        do {
            let dto = GeneralNoteInsert(workspaceId: wid, createdBy: uid, title: title, plainContent: plainContent, tags: tags)
            let created: GeneralNoteDTO = try await supabase
                .from("general_notes").insert(dto).select().single().execute().value
            generalNotes.insert(created, at: 0)
            return created
        } catch {
            showError("메모 추가에 실패했습니다")
            return nil
        }
    }

    func updateGeneralNote(_ item: GeneralNoteDTO) async {
        // Optimistic update
        if let idx = generalNotes.firstIndex(where: { $0.id == item.id }) {
            generalNotes[idx] = item
        }
        do {
            try await supabase.from("general_notes").update(item).eq("id", value: item.id.uuidString).execute()
        } catch {
            await fetchGeneralNotes()
            showError("메모 수정에 실패했습니다")
        }
    }

    func deleteGeneralNote(id: UUID) async {
        let backup = generalNotes
        generalNotes.removeAll { $0.id == id }
        do {
            try await supabase.from("general_notes").delete().eq("id", value: id.uuidString).execute()
        } catch {
            generalNotes = backup
            showError("삭제에 실패했습니다")
        }
    }
}

// MARK: - Insert DTOs
private struct SponsorshipInsert: Codable {
    let workspaceId: UUID; let createdBy: UUID; let brandName: String
    let productName: String; let details: String; let amount: Double
    let startDate: Date; let endDate: Date; let status: String
    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"; case createdBy = "created_by"
        case brandName = "brand_name"; case productName = "product_name"
        case details, amount; case startDate = "start_date"
        case endDate = "end_date"; case status
    }
}

private struct SettlementInsert: Codable {
    let workspaceId: UUID; let createdBy: UUID; let brandName: String
    let amount: Double; let fee: Double; let tax: Double
    let settlementDate: Date?; let isPaid: Bool; let memo: String
    let sponsorshipId: UUID?
    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"; case createdBy = "created_by"
        case brandName = "brand_name"; case amount, fee, tax, memo
        case settlementDate = "settlement_date"; case isPaid = "is_paid"
        case sponsorshipId = "sponsorship_id"
    }
}

private struct ReelsNoteInsert: Codable {
    let workspaceId: UUID; let createdBy: UUID; let title: String
    let plainContent: String; let status: String; let tags: [String]
    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"; case createdBy = "created_by"
        case title; case plainContent = "plain_content"; case status, tags
    }
}

private struct GeneralNoteInsert: Codable {
    let workspaceId: UUID; let createdBy: UUID; let title: String
    let plainContent: String; let tags: [String]
    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"; case createdBy = "created_by"
        case title; case plainContent = "plain_content"; case tags
    }
}

import Foundation
import UserNotifications

/// Local notifications for sponsorship deadlines.
///
/// Schedules:
/// - D-1 at 09:00 the day before `endDate`
/// - D-Day at 09:00 on `endDate`
///
/// Skips sponsorships whose status is `completed` or whose `endDate` is in the past.
/// On every refresh we clear ALL pending notifications and re-add — keeps state
/// in sync with the latest sponsorship data without bookkeeping.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    private var requestedPermission = false

    /// Request permission on first call; subsequent calls are no-ops.
    func requestPermissionIfNeeded() async {
        guard !requestedPermission else { return }
        requestedPermission = true
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("[Notification] permission error: \(error)")
        }
    }

    /// Rebuild the entire schedule from the given sponsorships.
    /// Safe to call on every DataManager.fetchSponsorships().
    func scheduleAll(sponsorships: [SponsorshipDTO]) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        // Clear previously scheduled (we own all influe-* identifiers)
        let pending = await center.pendingNotificationRequests()
        let influeIds = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("influe-sponsor-") }
        center.removePendingNotificationRequests(withIdentifiers: influeIds)

        let now = Date()
        let cal = Calendar.current

        for s in sponsorships {
            guard s.sponsorshipStatus != .completed else { continue }
            guard s.endDate > now else { continue }

            // D-1 at 09:00
            if let dMinus1Date = nineAM(on: cal.date(byAdding: .day, value: -1, to: s.endDate) ?? s.endDate, cal: cal),
               dMinus1Date > now {
                let body = "내일 마감이에요. 잊지 마세요!"
                addRequest(
                    id: "influe-sponsor-\(s.id.uuidString)-d1",
                    title: "⏰ \(s.brandName)",
                    body: body,
                    fireDate: dMinus1Date
                )
            }

            // D-Day at 09:00
            if let dDayDate = nineAM(on: s.endDate, cal: cal), dDayDate > now {
                addRequest(
                    id: "influe-sponsor-\(s.id.uuidString)-d0",
                    title: "🔥 \(s.brandName) - 오늘 마감!",
                    body: "오늘 \(s.brandName) 협찬 마감이에요. 빠르게 정리해 보세요.",
                    fireDate: dDayDate
                )
            }
        }
    }

    /// Cancel notifications for a specific sponsorship (e.g., on delete).
    func cancel(sponsorshipId: UUID) {
        let ids = [
            "influe-sponsor-\(sponsorshipId.uuidString)-d1",
            "influe-sponsor-\(sponsorshipId.uuidString)-d0",
        ]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    private func nineAM(on date: Date, cal: Calendar) -> Date? {
        cal.date(bySettingHour: 9, minute: 0, second: 0, of: date)
    }

    private func addRequest(id: String, title: String, body: String, fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] add error: \(error)")
            }
        }
    }
}

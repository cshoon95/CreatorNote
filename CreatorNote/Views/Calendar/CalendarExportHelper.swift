import Foundation
@preconcurrency import EventKit

final class CalendarExportHelper {

    private nonisolated(unsafe) static let eventStore = EKEventStore()

    // MARK: - Authorization

    private static func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestWriteOnlyAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Export Single Sponsorship

    static func exportToCalendar(sponsorship: SponsorshipDTO) async -> Bool {
        guard await requestAccess() else { return false }

        let event = EKEvent(eventStore: eventStore)
        event.title = "\(sponsorship.brandName) - \(sponsorship.productName)"
        event.startDate = sponsorship.startDate
        event.endDate = sponsorship.endDate
        event.notes = sponsorship.details
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Alarm 1 day before endDate
        if let alarmDate = Calendar.current.date(byAdding: .day, value: -1, to: sponsorship.endDate) {
            let offset = alarmDate.timeIntervalSince(sponsorship.endDate)
            event.addAlarm(EKAlarm(relativeOffset: offset))
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Export All Sponsorships

    static func exportAll(sponsorships: [SponsorshipDTO]) async -> Int {
        var successCount = 0
        for sponsorship in sponsorships {
            let success = await exportToCalendar(sponsorship: sponsorship)
            if success { successCount += 1 }
        }
        return successCount
    }
}

import Foundation
import UIKit
@preconcurrency import Supabase

@MainActor @Observable
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private var supabase: SupabaseClient { SupabaseManager.shared.client }
    private var userId: UUID? { AuthManager.shared.currentUser?.id }
    private var workspaceId: UUID? { WorkspaceManager.shared.currentWorkspace?.id }

    private init() {}

    // MARK: - App Events

    func trackEvent(_ name: String, type: String = "screen_view", metadata: [String: String] = [:]) {
        guard let uid = userId else { return }
        let wid = workspaceId?.uuidString ?? ""
        let metaJSON = metadata.isEmpty ? "{}" : ((try? String(data: JSONSerialization.data(withJSONObject: metadata), encoding: .utf8)) ?? "{}")
        Task.detached {
            do {
                try await SupabaseManager.shared.client.from("app_events").insert([
                    "user_id": uid.uuidString,
                    "workspace_id": wid,
                    "event_type": type,
                    "event_name": name,
                    "metadata": metaJSON,
                ]).execute()
            } catch {
                print("[Analytics] event error: \(error.localizedDescription)")
            }
        }
    }

    func trackScreenView(_ screen: String) {
        trackEvent(screen, type: "screen_view")
    }

    func trackAction(_ action: String, metadata: [String: String] = [:]) {
        trackEvent(action, type: "action", metadata: metadata)
    }

    // MARK: - Error Logging

    func logError(message: String, screen: String = "", type: String = "runtime") {
        guard let uid = userId else { return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let osVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        Task.detached {
            do {
                let deviceInfo: [String: String] = [
                    "model": model,
                    "os": osVersion,
                    "app_version": version,
                    "build": build,
                ]
                let deviceJSON = (try? String(data: JSONSerialization.data(withJSONObject: deviceInfo), encoding: .utf8)) ?? "{}"
                try await SupabaseManager.shared.client.from("error_logs").insert([
                    "user_id": uid.uuidString,
                    "error_type": type,
                    "error_message": message,
                    "screen": screen,
                    "device_info": deviceJSON,
                ]).execute()
            } catch {
                print("[Analytics] log error: \(error.localizedDescription)")
            }
        }
    }
}

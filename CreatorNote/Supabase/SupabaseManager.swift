import Foundation
@preconcurrency import Supabase

@MainActor @Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://wrnglzfsgoujboyjomuu.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndybmdsemZzZ291amJveWpvbXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTgyOTQsImV4cCI6MjA5MTE3NDI5NH0.QAeq0tzH_XDXTuL2UpAbNcaDkXiY3mKEjZVBL8AVhcA"
        )
    }
}

import Foundation
import UIKit
@preconcurrency import Supabase

@MainActor
final class StorageManager {
    static let shared = StorageManager()
    private var supabase: SupabaseClient { SupabaseManager.shared.client }
    private let bucket = "note-images"
    private let baseURL = "https://wrnglzfsgoujboyjomuu.supabase.co/storage/v1/object/public/note-images/"

    private init() {}

    func uploadImages(_ images: [UIImage]) async -> [String] {
        var urls: [String] = []
        for image in images {
            guard let data = image.jpegData(compressionQuality: 0.7) else { continue }
            let fileName = "\(UUID().uuidString).jpg"
            let path = "\(AuthManager.shared.currentUser?.id.uuidString ?? "unknown")/\(fileName)"
            do {
                try await supabase.storage.from(bucket).upload(path, data: data, options: .init(contentType: "image/jpeg"))
                urls.append(baseURL + path)
            } catch {
                print("[Storage] upload error: \(error.localizedDescription)")
            }
        }
        return urls
    }

    func deleteImage(url: String) async {
        let path = url.replacingOccurrences(of: baseURL, with: "")
        do {
            try await supabase.storage.from(bucket).remove(paths: [path])
        } catch {
            print("[Storage] delete error: \(error.localizedDescription)")
        }
    }
}

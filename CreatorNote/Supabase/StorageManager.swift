import Foundation
import UIKit
@preconcurrency import Supabase

@MainActor
final class StorageManager {
    static let shared = StorageManager()
    private var supabase: SupabaseClient { SupabaseManager.shared.client }
    private let bucket = "note-images"

    private init() {}

    /// Upload images and return storage paths (not full URLs)
    func uploadImages(_ images: [UIImage]) async -> [String] {
        var paths: [String] = []
        for image in images {
            guard let data = image.jpegData(compressionQuality: 0.7) else { continue }
            let fileName = "\(UUID().uuidString).jpg"
            let path = "\(AuthManager.shared.currentUser?.id.uuidString ?? "unknown")/\(fileName)"
            do {
                try await supabase.storage.from(bucket).upload(path, data: data, options: .init(contentType: "image/jpeg"))
                paths.append(path)
            } catch {
                print("[Storage] upload error: \(error.localizedDescription)")
            }
        }
        return paths
    }

    /// Get a signed URL for a storage path (valid for 1 hour)
    func signedURL(for path: String) async -> URL? {
        do {
            return try await supabase.storage.from(bucket).createSignedURL(path: path, expiresIn: 3600)
        } catch {
            print("[Storage] signedURL error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get signed URLs for multiple paths
    func signedURLs(for paths: [String]) async -> [String: URL] {
        var result: [String: URL] = [:]
        for path in paths {
            if let url = await signedURL(for: path) {
                result[path] = url
            }
        }
        return result
    }

    /// Delete a single image by its storage path
    func deleteImage(path: String) async {
        do {
            try await supabase.storage.from(bucket).remove(paths: [path])
        } catch {
            print("[Storage] delete error: \(error.localizedDescription)")
        }
    }

    /// Delete multiple images by their storage paths
    func deleteImages(paths: [String]) async {
        guard !paths.isEmpty else { return }
        do {
            try await supabase.storage.from(bucket).remove(paths: paths)
        } catch {
            print("[Storage] delete error: \(error.localizedDescription)")
        }
    }
}

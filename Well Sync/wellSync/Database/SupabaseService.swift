//
//  SupabaseManager.swift
//  wellSync
//
//  Created by Rishika Mittal on 20/03/26.
//

import Foundation
import UIKit
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient()
    }
    
    func signUp(email: String, password: String) async throws -> UUID {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            let user = response.user
            return user.id
        }
        
        // MARK: - Sign In (for Login Screen)
        // Returns the logged-in auth user's UUID
        func signIn(email: String, password: String) async throws -> UUID {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            return session.user.id
        }
        
        // MARK: - Sign Out
        func signOut() async throws {
            try await client.auth.signOut()
            SessionManager.shared.clearSession()
        }
        
        // MARK: - Get current Auth session (used on app launch)
        // Returns the auth user's UUID if they are still logged in, nil otherwise
        func getCurrentAuthUserID() async -> UUID? {
            do {
                let session = try await client.auth.session
                return session.user.id
            } catch {
                return nil
            }
        }
        
        // MARK: - Determine Role from auth_id
        // Checks doctors table first, then patients table
        func resolveRole(authID: UUID) async throws -> UserRole {
            // Try doctors table
            let doctors: [Doctor] = try await client
                .from("doctors")
                .select()
                .eq("auth_id", value: authID.uuidString)
                .limit(1)
                .execute()
                .value
            
            if !doctors.isEmpty {
                return .doctor
            }
            
            // Try patients table
            let patients: [Patient] = try await client
                .from("patients")
                .select()
                .eq("auth_id", value: authID.uuidString)
                .limit(1)
                .execute()
                .value
            
            if !patients.isEmpty {
                return .patient
            }
            
            throw NSError(domain: "AuthError", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "No profile found for this user"])
        }
}

extension SupabaseManager {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Image Upload
    // ─────────────────────────────────────────────────────────────────────────

    /// Compresses `image` to JPEG, uploads it to the `session-media` bucket
    /// under `images/<uuid>.jpg`, and returns the resulting **storage path**
    /// (e.g. "images/7F3A...jpg").
    ///
    /// Usage:
    /// ```swift
    /// let path = try await SupabaseManager.shared.uploadImage(selectedImage)
    /// let publicURL = SupabaseManager.shared.publicURL(for: path)
    /// ```
    func uploadImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) async throws -> String {
        // 1. Convert UIImage → JPEG Data
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw UploadError.imageConversionFailed
        }

        // 2. Build a unique file name so every upload is distinct
        let fileName = "\(UUID().uuidString).jpg"
        let storagePath = "images/\(fileName)"

        // 3. Upload to Supabase Storage
        try await client.storage
            .from("session-media")
            .upload(
                storagePath,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        return storagePath
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Audio Upload
    // ─────────────────────────────────────────────────────────────────────────

    /// Reads audio data from `localURL` (a file:// URL returned by
    /// `UIDocumentPickerViewController`), uploads it to the `session-media`
    /// bucket under `audio/<uuid>.<ext>`, and returns the storage path.
    ///
    /// The file must be accessible while this function runs.
    /// For security-scoped resources (iCloud / Files app), the caller is
    /// responsible for calling `startAccessingSecurityScopedResource()` before
    /// and `stopAccessingSecurityScopedResource()` after this call.
    func uploadAudio(from localURL: URL) async throws -> String {
        // 1. Read the file into memory
        let audioData = try Data(contentsOf: localURL)

        // 2. Preserve original extension (m4a, mp3, wav, etc.)
        let ext = localURL.pathExtension.isEmpty ? "m4a" : localURL.pathExtension
        let fileName = "\(UUID().uuidString).\(ext)"
        let storagePath = "audio/\(fileName)"

        // 3. Pick an appropriate MIME type
        let mimeType: String
        switch ext.lowercased() {
        case "mp3":  mimeType = "audio/mpeg"
        case "wav":  mimeType = "audio/wav"
        case "aac":  mimeType = "audio/aac"
        default:     mimeType = "audio/mp4"   // covers .m4a
        }

        // 4. Upload to Supabase Storage
        try await client.storage
            .from("session-media")
            .upload(
                storagePath,
                data: audioData,
                options: FileOptions(contentType: mimeType)
            )

        return storagePath
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Public URL Helper
    // ─────────────────────────────────────────────────────────────────────────

    /// Returns the public URL string for a given storage path.
    /// Only works if the `session-media` bucket has public access enabled.
    func publicURL(for storagePath: String) -> String {
        let base = "https://qzcfmkjvenxbrndlgowp.supabase.co/storage/v1/object/public/session-media"
        return "\(base)/\(storagePath)"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Errors
    // ─────────────────────────────────────────────────────────────────────────

    enum UploadError: LocalizedError {
        case imageConversionFailed

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image to JPEG data."
            }
        }
    }
}

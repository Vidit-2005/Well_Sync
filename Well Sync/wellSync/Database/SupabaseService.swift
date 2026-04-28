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
        client = SupabaseClient(supabaseURL: sURL, supabaseKey: sKey)
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

    func getCurrentSessionTokens() async -> (accessToken: String, refreshToken: String)? {
        do {
            let session = try await client.auth.session
            return (session.accessToken, session.refreshToken)
        } catch {
            print("Could not snapshot current session: \(error)")
            return nil
        }
    }

    /// Restores a previously snapshotted session.
    /// Call this AFTER patient signup to put the doctor's session back.
    func restoreSession(accessToken: String, refreshToken: String) async {
        do {
            try await client.auth.setSession(accessToken: accessToken,
                                               refreshToken: refreshToken)
            print("✅ Doctor session restored after patient creation.")
        } catch {
            print("⚠️ Could not restore doctor session: \(error)")
        }
    }

    /// Signs out from Supabase without touching SessionManager.
    /// Used to evict a rogue (patient) session detected on app launch.
    func signOutSilently() async {
        do {
            try await client.auth.signOut()
        } catch {
            print("Silent sign-out error (non-fatal): \(error)")
        }
    }
}

extension SupabaseManager {
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

    func publicURL(for storagePath: String) -> String {
        let base = "https://qzcfmkjvenxbrndlgowp.supabase.co/storage/v1/object/public/session-media"
        return "\(base)/\(storagePath)"
    }

    enum UploadError: LocalizedError {
        case imageConversionFailed

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image to JPEG data."
            }
        }
    }
    func downloadAudioToLocal(from path: String) async throws -> URL {
        let urlString = publicURL(for: path)

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")

        try data.write(to: tempURL)

        return tempURL
    }
    func downloadSessionImage(from path: String) async throws -> UIImage {
        let urlString = publicURL(for: path)
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageDecodeError", code: 0)
        }

        return image
    }
    func getAudioURL(for path: String) -> URL? {
        return URL(string: publicURL(for: path))
    }
}

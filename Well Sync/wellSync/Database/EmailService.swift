//
//  EmailService.swift
//  wellSync
//
// Created by Vidit Saran Agarwal on 28/04/26.
//
//  Calls the Supabase Edge Function `send-patient-welcome` to deliver
//  login credentials to a newly registered patient via Gmail SMTP.
//
//  HOW IT WORKS
//  ─────────────────────────────────────────────────────────────────
//  1. The iOS app collects the patient email + generated password.
//  2. It POSTs that data (+ doctor name) to the Edge Function URL.
//  3. The Edge Function (Deno / Node) sends the email through Gmail
//     SMTP using a Gmail App Password stored as a Supabase secret.
//  4. The app receives a 200 OK (or an error) and shows feedback.
//
//  NOTE: Never put Gmail credentials inside the app binary.
//        They belong only in Supabase → Project Settings → Secrets.
//

import Foundation

final class EmailService {

    static let shared = EmailService()
    private init() {}
    
    private let edgeFunctionURL = URL(
        string: "https://qzcfmkjvenxbrndlgowp.supabase.co/functions/v1/send-patient-welcome"
    )!

    private let anonKey = sKey

    func sendPatientWelcomeEmail(patientEmail: String,patientName: String,password: String,doctorName: String) async throws {

        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)",  forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "patientEmail": patientEmail,
            "patientName":  patientName,
            "password":     password,
            "doctorName":   doctorName
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw EmailServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw EmailServiceError.serverError(http.statusCode, body)
        }
    }

    enum EmailServiceError: LocalizedError {
        case invalidResponse
        case serverError(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Unexpected response from the email server."
            case .serverError(let code, let body):
                return "Email server returned \(code): \(body)"
            }
        }
    }
}

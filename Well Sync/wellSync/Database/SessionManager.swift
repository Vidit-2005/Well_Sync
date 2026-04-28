//  SessionManager.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 26/03/26.
//
import Foundation

enum UserRole: String {
    case doctor  = "doctor"
    case patient = "patient"
    case none    = "none"
}

final class SessionManager {

    static let shared = SessionManager()
    private init() {}

    private let roleKey      = "wellsync_user_role"
    private let doctorIDKey  = "wellsync_doctor_id"
    private let patientIDKey = "wellsync_patient_id"
    private let authIDKey    = "wellsync_auth_id"

    var currentDoctor:  Doctor?
    var currentPatient: Patient?

    var currentRole: UserRole {
        get {
            let raw = UserDefaults.standard.string(forKey: roleKey) ?? "none"
            return UserRole(rawValue: raw) ?? .none
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: roleKey) }
    }

    var persistedDoctorID: String? {
        get { UserDefaults.standard.string(forKey: doctorIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: doctorIDKey) }
    }

    var persistedPatientID: String? {
        get { UserDefaults.standard.string(forKey: patientIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: patientIDKey) }
    }

    var persistedAuthID: String? {
        get { UserDefaults.standard.string(forKey: authIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: authIDKey) }
    }

    // MARK: - Save session after successful login
    func saveSession(role: UserRole,
                     authID:    UUID? = nil,
                     doctorID:  UUID? = nil,
                     patientID: UUID? = nil) {
        currentRole = role
        if let authID    = authID    { persistedAuthID    = authID.uuidString }
        if let doctorID  = doctorID  { persistedDoctorID  = doctorID.uuidString }
        if let patientID = patientID { persistedPatientID = patientID.uuidString }
    }

    // MARK: - Clear session on logout
    func clearSession() {
        currentRole    = .none
        currentDoctor  = nil
        currentPatient = nil
        persistedAuthID    = nil
        persistedDoctorID  = nil
        persistedPatientID = nil
        UserDefaults.standard.removeObject(forKey: roleKey)
        UserDefaults.standard.removeObject(forKey: authIDKey)
        UserDefaults.standard.removeObject(forKey: doctorIDKey)
        UserDefaults.standard.removeObject(forKey: patientIDKey)
    }

    // MARK: - Helpers
    var isLoggedIn: Bool { currentRole != .none }
    var isDoctor:   Bool { currentRole == .doctor }
    var isPatient:  Bool { currentRole == .patient }
}

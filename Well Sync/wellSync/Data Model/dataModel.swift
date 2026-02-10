//
//  dataModel.swift
//  wellSync
//
//  Created by GEU on 09/02/26.
//

import Foundation

struct PsychologistDashboardStats: Codable {
    var activePatientsCount: Int
    var activePatientsDelta: Int
    var todaysSessionsCount: Int
}

enum SessionStatus: String, Codable {
    case upcoming
    case completed
    case missed
}

struct PatientSessionCard: Identifiable {
    var id: UUID
    var name: String
    var profileImage: [String]
    var disorder: String
    var sessionCount: Int
    var lastSessionDate: Date
    var sessionTimeToday: String
    var activityCompletionPercent: Int
    //var statusIndicator: PatientStatus
    var sessionStatus: SessionStatus
}


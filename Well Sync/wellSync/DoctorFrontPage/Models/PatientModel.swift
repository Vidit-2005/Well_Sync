//
//  Patient.swift
//  wellSync
//
//  Created by Pranjal on 05/02/26.
//

import UIKit

struct PatientModel {
    let id: UUID
    let name: String
    let condition: String
    let sessionCount: Int
    let lastSessionDate: String
    let sessionTime: String
    let progress: Float
    let imageName: String
    let status: PatientStatus
}

enum PatientStatus {
    case normal
    case warning
    case critical
    case completed
}

//
//  PatientService.swift
//  wellSync
//
//  Created by Pranjal on 05/02/26.
//

import UIKit

class PatientService {

    static let shared = PatientService()
    private init() {}

    
    func fetchPatients() -> [PatientModel] {

        return [
            PatientModel(id: UUID(),
                    name: "Vidit Saran Agarwal",
                    condition: "BPD",
                    sessionCount: 7,
                    lastSessionDate: "11 Nov 25",
                    sessionTime: "10:30 AM",
                    progress: 0.8,
                    imageName: "profile",
                    status: .normal),

            PatientModel(id: UUID(),
                    name: "Kavya Bansal",
                    condition: "ADHD",
                    sessionCount: 5,
                    lastSessionDate: "9 Nov 25",
                    sessionTime: "12:30 PM",
                    progress: 0.8,
                    imageName: "profile",
                    status: .critical),

            PatientModel(id: UUID(),
                    name: "Rishika Mittal",
                    condition: "Bipolar",
                    sessionCount: 6,
                    lastSessionDate: "13 Nov 25",
                    sessionTime: "09:30 AM",
                    progress: 0.8,
                    imageName: "profile",
                    status: .warning)
        ]
    }
}

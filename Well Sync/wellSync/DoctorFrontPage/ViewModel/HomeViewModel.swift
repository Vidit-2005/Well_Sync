//
//  HomeViewModel.swift
//  wellSync
//
//  Created by Pranjal on 05/02/26.
//

import UIKit

class HomeViewModel {

    private var patients: [PatientModel] = []

    func loadPatients() {
        patients = PatientService.shared.fetchPatients()
    }

    func numberOfPatients() -> Int {
        return patients.count
    }

    func patient(at index: Int) -> PatientModel {
        return patients[index]
    }
}

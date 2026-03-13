//
//  AppointmentCollectionViewController.swift
//  wellSync
//
//  Created by Pranjal on 11/03/26.
//

import UIKit

class AppointmentCollectionViewController: UICollectionViewController {

    var currentDoctor: Doctor?
    var selectedDate: Date = Date()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(
                UINib(nibName: "AppointmentCalenderCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "AppointmentViewCell"
            )

            collectionView.register(
                UINib(nibName: "PatientCellAppointment", bundle: nil),
                forCellWithReuseIdentifier: "PatientCellAppointment"
            )
    }

    var appointmentsForSelectedDay: [Patient] {

        guard let doctor = currentDoctor else { return [] }

        let calendar = Calendar.current

        return doctor.Patients.filter {
            calendar.isDate($0.nextSessionDate,
                            equalTo: selectedDate,
                            toGranularity: .day)
        }
        .sorted {
            $0.nextSessionDate < $1.nextSessionDate
        }
        
    }

    // MARK: - Sections

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    // MARK: - Items

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {

        if section == 0 { return 1 }

        return appointmentsForSelectedDay.count
    }

    // MARK: - Cells

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "AppointmentViewCell",
                for: indexPath
            ) as! AppointmentCalenderCollectionViewCell

            cell.delegate = self
            return cell
        }

        let patient = appointmentsForSelectedDay[indexPath.row]

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PatientCellAppointment",
            for: indexPath
        ) as! PatientCellAppointment

        cell.configure(with: patient)

        return cell
    }
}

extension AppointmentCollectionViewController: CalendarSelectionDelegate {

    func didSelectDate(_ date: Date) {

        selectedDate = date

        collectionView.reloadSections(IndexSet(integer: 1))

    }
}

extension AppointmentCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        

        if indexPath.section == 0 {
            return CGSize(width: collectionView.frame.width, height: 250)
        }

        return CGSize(width: collectionView.frame.width, height: 120)
    }
}

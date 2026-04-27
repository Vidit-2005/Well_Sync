////
////  MoodAnalysisCollectionViewController.swift
////  wellSync
////
////  Created by Pranjal on 04/02/26.
////
//
//import UIKit
//class AppointmentCollectionViewController: UICollectionViewController {
//    
//    private var selectedSegmentIndex: Int = 0
//    
//    var patients: [Patient] = []
//    var doctorID: UUID!   // MUST be set before this screen loads
//    var selectedDate: Date = Date()
//    private var calendarHeight: CGFloat = 300
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        collectionView.backgroundColor = .systemBackground
//        loadPatients()
//        collectionView.register(
//            UINib(nibName: "CalendarCellAppointment", bundle: nil),
//            forCellWithReuseIdentifier: "calenderAp"
//        )
//        
//        collectionView.register(
//            UINib(nibName: "PatientCellAppointment", bundle: nil),
//            forCellWithReuseIdentifier: "PatientCellAppointment"
//        )
//        collectionView.register(
//            UINib(nibName: "SectionHeaderViewAp", bundle: nil),
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
//            withReuseIdentifier: "SectionHeaderViewAp"
//        )
//       
//        
//        
//        collectionView.collectionViewLayout = generateLayout()
//    }
//    
//    
//    // MARK: - Sections
//    
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 3
//    }
//    
//    override func collectionView(_ collectionView: UICollectionView,
//                                 numberOfItemsInSection section: Int) -> Int {
//        switch section {
//        case 2:
//            return filteredPatients().count   // 🔥 MULTIPLE CARDS
//        default:
//            return 1
//        }
//    }
//    
//    func loadPatients() {
//        Task {
//            do {
//                let fetchedPatients = try await AccessSupabase.shared.fetchPatients(for: doctorID)
//                
//                await MainActor.run {
//                    self.patients = fetchedPatients
//                    self.collectionView.reloadSections(IndexSet(integer: 2))
//                }
//                
//            } catch {
//                print("Error fetching patients:", error)
//            }
//        }
//    }
//    
//    // MARK: - Cells
//    
//    override func collectionView(_ collectionView: UICollectionView,
//                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        
//        switch indexPath.section {
//            
//        case 0:
//            return collectionView.dequeueReusableCell(withReuseIdentifier: "segment", for: indexPath)
//            
//        case 1:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "calenderAp",
//                for: indexPath
//            ) as! CalendarCellAppointment
//            
//            style(cell)
//            
//            // ✅ CRITICAL: listen to FSCalendar height
//            cell.onHeightChange = { [weak self] newHeight in
//                guard let self = self else { return }
//                
//                // small padding for card
//                self.calendarHeight = newHeight + 16
//                
//                // update layout smoothly
//                UIView.animate(withDuration: 0.25) {
//                    self.collectionView.collectionViewLayout.invalidateLayout()
//                    self.collectionView.layoutIfNeeded()
//                }
//            }
//            cell.onDateSelected = { [weak self] date in
//                          guard let self = self else { return }
//                          
//                          self.selectedDate = date
//                          
//                          print("Selected:", date)
//                          
//                          self.collectionView.reloadSections(IndexSet(integer: 2))
//                      }
//            cell.configure(segment: selectedSegmentIndex)
//            
//            return cell
//            
//        case 2:
//            let cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: "PatientCellAppointment",
//                for: indexPath
//            ) as! PatientCellAppointment
//            
//            let patient = filteredPatients()[indexPath.item]
//            print("Selected Date:", selectedDate)
//            print("Filtered Count:", filteredPatients().count)
//            // ✅ Use your cell's configure method
//            cell.configure(
//                name: patient.name,
//                condition: patient.condition!,
//                previousSessionDate: patient.previousSessionDate,
//                imageName: patient.imageURL   // ⚠️ see note below
//            )
//            
//            // 🔥 Set session time (not handled in configure)
//            let formatter = DateFormatter()
//            formatter.dateFormat = "hh:mm a"
//            cell.sessionLabel.text = formatter.string(from: patient.nextSessionDate!)
//            
//            style(cell)
//            
//            return cell
//            
//        default:
//            return UICollectionViewCell()
//        }
//    }
//    
//    
//    
//    func filteredPatients() -> [Patient] {
//           let calendar = Calendar.current
//           
//           return patients.filter {
//               guard let sessionDate = $0.nextSessionDate else { return false }
//               
//               return calendar.isDate(sessionDate,
//                                      equalTo: selectedDate,
//                                      toGranularity: .day)
//           }
//       }
//    
//    
//    override func collectionView(
//        _ collectionView: UICollectionView,
//        viewForSupplementaryElementOfKind kind: String,
//        at indexPath: IndexPath
//    ) -> UICollectionReusableView {
//        
//        guard kind == UICollectionView.elementKindSectionHeader else {
//            return UICollectionReusableView()
//        }
//
//        let header = collectionView.dequeueReusableSupplementaryView(
//            ofKind: kind,
//            withReuseIdentifier: "SectionHeaderViewAp",
//            for: indexPath
//        ) as! SectionHeaderViewAp
//
//        switch indexPath.section {
//        case 1:
//            header.configure(withTitle: "Appointments")
//        case 2:
//            header.configure(withTitle: "Patients")
//        default:
//            header.configure(withTitle: "")
//        }
//
//        return header
//    }
//    // MARK: - Layout
//    
//    func generateLayout() -> UICollectionViewCompositionalLayout {
//        return UICollectionViewCompositionalLayout { sectionIndex, _ in
//            let headerSize = NSCollectionLayoutSize(
//                widthDimension: .fractionalWidth(1.0),
//                heightDimension: .absolute(40)
//            )
//
//            let header = NSCollectionLayoutBoundarySupplementaryItem(
//                layoutSize: headerSize,
//                elementKind: UICollectionView.elementKindSectionHeader,
//                alignment: .top
//            )
//            let height: NSCollectionLayoutDimension
//            
//            switch sectionIndex {
//            case 0:
//                height = .estimated(50)
//                
//            case 1:
//                // ✅ dynamic height instead of hardcoded
//                
//                height = .absolute(self.calendarHeight)
//                
//            case 2:
//                let itemSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .estimated(140) // 🔥 small, dynamic
//                )
//                
//                let item = NSCollectionLayoutItem(layoutSize: itemSize)
//                
//                let groupSize = NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .estimated(140)
//                )
//                
//                let group = NSCollectionLayoutGroup.vertical(
//                    layoutSize: groupSize,
//                    subitems: [item]
//                )
//                
//                let section = NSCollectionLayoutSection(group: group)
//                section.boundarySupplementaryItems = [header]
//                section.interGroupSpacing = 12
//                section.contentInsets = NSDirectionalEdgeInsets(
//                    top: 16, leading: 16, bottom: 16, trailing: 16
//                )
//                
//                return section
//                
//            default:
//                height = .absolute(100)
//            }
//            
//            let item = NSCollectionLayoutItem(
//                layoutSize: NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: .fractionalHeight(1.0)
//                )
//            )
//            
//            let group = NSCollectionLayoutGroup.vertical(
//                layoutSize: NSCollectionLayoutSize(
//                    widthDimension: .fractionalWidth(1.0),
//                    heightDimension: height
//                ),
//                subitems: [item]
//            )
//            
//            let section = NSCollectionLayoutSection(group: group)
//         
//            section.contentInsets = NSDirectionalEdgeInsets(
//                top: sectionIndex == 0 ? 0 : 16,
//                leading: sectionIndex == 2 ? 0 : 16,
//                bottom: 16,
//                trailing: sectionIndex == 2 ? 0 : 16
//            )
//            
//            return section
//        }
//    }
//    
//    // MARK: - Styling
//    
//    func style(_ cell: UICollectionViewCell) {
//        cell.layer.cornerRadius = 16
//        cell.layer.masksToBounds = true
//    }
//    // MARK: - Segment Toggle (FIXED INDEX)
//    
//    @IBAction func sectionChanged(_ sender: UISegmentedControl) {
//        selectedSegmentIndex = sender.selectedSegmentIndex
//        if let cell = collectionView.cellForItem(
//                 at: IndexPath(item: 0, section: 1)
//             ) as? CalendarCellAppointment {
//                 cell.configure(segment: selectedSegmentIndex)
//             }
//    }
//}
//

import UIKit

 
class AppointmentCollectionViewController: UICollectionViewController {

    private var selectedSegmentIndex: Int = 0

    var appointments: [AppointmentWithPatient] = []
    var doctorID: UUID!
    var selectedDate: Date = Date()
    private var calendarHeight: CGFloat = 300

    // ✅ ADD THESE (IMPORTANT)
    var selectedPatient: Patient?
    var selectedAppointment: AppointmentWithPatient?
    var sessionCountByPatient: [UUID: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .systemBackground

        collectionView.register(
            UINib(nibName: "CalendarCellAppointment", bundle: nil),
            forCellWithReuseIdentifier: "calenderAp"
        )

        collectionView.register(
            UINib(nibName: "PatientCellAppointment", bundle: nil),
            forCellWithReuseIdentifier: "PatientCellAppointment"
        )

        collectionView.register(
            UINib(nibName: "SectionHeaderViewAp", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeaderViewAp"
        )
        collectionView.register(
            UINib(nibName: "PatientCell", bundle: nil),
            forCellWithReuseIdentifier: "PatientCell"
        )

        collectionView.collectionViewLayout = generateLayout()
        loadAppointments()
    }

    // MARK: - DATA LOAD

//    func loadAppointments() {
//        guard let doctorID else { return }
//
//        Task {
//            do {
//                let data = try await AccessSupabase.shared
//                    .fetchAllAppointmentsWithPatients(doctorID: doctorID)
//
//                await MainActor.run {
//                    self.appointments = data
//                    self.collectionView.reloadSections(IndexSet(integer: 2))
//                }
//
//            } catch {
//                print("Error:", error)
//            }
//        }
//    }
    
    func loadAppointments() {
        guard let doctorID else { return }

        Task {
            do {
                let data = try await AccessSupabase.shared
                    .fetchAllAppointmentsWithPatients(doctorID: doctorID)

                // ✅ Extract patient IDs
                let patientIDs = data.map { $0.patient.patientID }

                // ✅ Fetch counts
                let counts = try await AccessSupabase.shared
                    .fetchCompletedSessionCounts(patientIDs: patientIDs)

                await MainActor.run {
                    self.appointments = data
                    self.sessionCountByPatient = counts   // 🔥 important
                    self.collectionView.reloadSections(IndexSet(integer: 2))
                }

            } catch {
                print("Error:", error)
            }
        }
    }

    // MARK: - FILTER

    func filteredAppointments() -> [AppointmentWithPatient] {
        let calendar = Calendar.current
        return appointments.filter {
            calendar.isDate($0.scheduledAt, inSameDayAs: selectedDate)
        }
    }

    // MARK: - COLLECTION VIEW

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return section == 2 ? filteredAppointments().count : 1
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case 0:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "segment", for: indexPath)

        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "calenderAp",
                for: indexPath
            ) as! CalendarCellAppointment

            style(cell)

            cell.onHeightChange = { [weak self] newHeight in
                guard let self else { return }
                self.calendarHeight = newHeight + 16

                UIView.animate(withDuration: 0.25) {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    self.collectionView.layoutIfNeeded()
                }
            }

            cell.onDateSelected = { [weak self] date in
                guard let self else { return }
                self.selectedDate = date
                self.collectionView.reloadSections(IndexSet(integer: 2))
            }

            cell.configure(segment: selectedSegmentIndex)
            return cell

        case 2:
            let calendar = Calendar.current
                let isPastDate = calendar.compare(selectedDate, to: Date(), toGranularity: .day) == .orderedAscending

            if isPastDate {
                // 🔴 Past → Show PatientCell
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "PatientCell",
                    for: indexPath
                ) as! PatientCell
                
                let patient = appointments[indexPath.item].patient
                let count = sessionCountByPatient[patient.patientID] ?? 0
                cell.configureCell(with: patient, sessionCount: count)
                
                style(cell)
                return cell
            }else{
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "PatientCellAppointment",
                    for: indexPath
                ) as! PatientCellAppointment
                
                let appointment = filteredAppointments()[indexPath.item]
                let patient = appointment.patient
                
                // TIME
//                let formatter = DateFormatter()
//                formatter.dateFormat = "hh:mm a"
//                cell.time.text = formatter.string(from: appointment.scheduledAt)
                
                let count = sessionCountByPatient[patient.patientID] ?? 0
                // BASIC DATA
                
                cell.configure(
                    name: patient.name,
                    condition: patient.condition ?? "",
                    previousSessionDate: patient.previousSessionDate,
                    nextSessionDate: appointment.scheduledAt,
                    sessionCount: count,
                    imageName: nil
                )
                
                // ✅ BUTTON ACTIONS
                cell.onAction = { [weak self] action, _ in
                    guard let self = self else { return }
                    
                    switch action {
                        
                    case .reschedule:
                        self.selectedPatient = patient
                        self.selectedAppointment = appointment
                        
                        self.performSegue(
                            withIdentifier: "PatientDetail",
                            sender: PatientNavigationIntent.reschedule
                        )
                        
                    case .cancel:
                        self.cancelAppointment(appointment: appointment)
                    }
                }
                
                // IMAGE LOAD
                Task { [weak cell] in
                    guard let cell else { return }
                    
                    if let path = patient.imageURL {
                        let image = try? await AccessSupabase.shared.downloadImage(path: path)
                        
                        await MainActor.run {
                            cell.profileImage.image = image ?? UIImage(systemName: "person.circle")
                        }
                    }
                }
                
                style(cell)
                return cell
            }
        default:
            return UICollectionViewCell()
        }
    }

    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {

        guard indexPath.section == 2 else { return }

        let calendar = Calendar.current
        let isPastDate = calendar.compare(selectedDate, to: Date(), toGranularity: .day) == .orderedAscending

        if isPastDate {
            // 🔴 Past → PatientCell
            let patient = appointments[indexPath.item].patient

            let storyboard = UIStoryboard(name: "PatientDetail", bundle: nil)
            let vc = storyboard.instantiateViewController(
                withIdentifier: "PatientDetail"
            ) as! PatientDetailCollectionViewController

            vc.patient = patient

            navigationController?.pushViewController(vc, animated: true)

        } else {
            // 🟢 Today / Future → Appointment Cell
            let appointment = filteredAppointments()[indexPath.item]

            let storyboard = UIStoryboard(name: "PatientDetail", bundle: nil)
            let vc = storyboard.instantiateViewController(
                withIdentifier: "PatientDetail"
            ) as! PatientDetailCollectionViewController

            vc.patient = appointment.patient
            vc.selectedAppointment = appointment   // important if you need it

            navigationController?.pushViewController(vc, animated: true)
        }
    }
    // MARK: - CANCEL LOGIC

    func cancelAppointment(appointment: AppointmentWithPatient) {
        let alert = UIAlertController(
               title: "Cancel Appointment",
               message: "Are you sure you want to cancel this appointment?",
               preferredStyle: .alert
           )
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Cancel", style: .destructive) { _ in
            Task {
                do {
                    let id = appointment.appointmentId   // ✅ FIXED
                    
                    try await AccessSupabase.shared.deleteAppointment(id: id)
                    
                    try await AccessSupabase.shared
                        .clearNextSessionDate(patientID: appointment.patient.patientID)
                    
                    await MainActor.run {
                        self.loadAppointments()
                    }
                    
                } catch {
                    print("❌ Cancel error:", error)
                }
            }
        }
        alert.addAction(noAction)
            alert.addAction(yesAction)

            present(alert, animated: true)
    }

    // MARK: - SEGUE HANDLING (CRITICAL)

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PatientDetail" {

            let vc = segue.destination as! PatientDetailCollectionViewController

            vc.patient = selectedPatient
            vc.selectedAppointment = selectedAppointment

            if let intent = sender as? PatientNavigationIntent {
                vc.actionIntent = intent
            }
        }
    }

    // MARK: - HEADER

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionHeaderViewAp",
            for: indexPath
        ) as! SectionHeaderViewAp

        switch indexPath.section {
        case 1:
            header.configure(withTitle: "Appointments")
        case 2:
            header.configure(withTitle: "Patients")
        default:
            header.configure(withTitle: "")
        }

        return header
    }

    // MARK: - LAYOUT

    func generateLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(40)
            )

            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )

            let height: NSCollectionLayoutDimension

            switch sectionIndex {

            case 0:
                height = .estimated(50)

            case 1:
                height = .absolute(self.calendarHeight)

            case 2:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(140)
                    )
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(140)
                    ),
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [header]
                section.interGroupSpacing = 12
                section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
                return section

            default:
                height = .absolute(100)
            }

            let item = NSCollectionLayoutItem(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: height
                ),
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(
                top: sectionIndex == 0 ? 0 : 16,
                leading: sectionIndex == 2 ? 0 : 16,
                bottom: 16,
                trailing: sectionIndex == 2 ? 0 : 16
            )

            return section
        }
    }

    func style(_ cell: UICollectionViewCell) {
        cell.layer.cornerRadius = 16
        cell.layer.masksToBounds = true
    }
    @IBAction func sectionChanged(_ sender: UISegmentedControl) {
        selectedSegmentIndex = sender.selectedSegmentIndex

        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 1)) as? CalendarCellAppointment {
            cell.configure(segment: selectedSegmentIndex)
        }
    }
}

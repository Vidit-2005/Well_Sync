//
//  AllPatientCollectionViewController.swift
//  wellSync
//
//  Created by Pranjal on 11/03/26.
//

import UIKit

class AllPatientCollectionViewController: UICollectionViewController {

    var patients: [Patient] = []
    var filteredPatients: [Patient] = []
    var sessionCountByPatient: [UUID: Int] = [:]
    var viewModel: AccessSupabase?
    var doctor:Doctor?

    // MARK: - Sort

    @IBOutlet weak var sortBarButton: UIBarButtonItem!

    enum PatientSortOption {
        case name, condition
    }

    var currentSort: PatientSortOption = .name
    var isAscending: Bool = true // ✅ ADDED THIS

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = AccessSupabase.shared

        setupCollectionView()

        // Attach the sort menu to the storyboard bar button
        sortBarButton.menu = buildSortMenu()

        collectionView.setCollectionViewLayout(createLayout(), animated: false)

        Task {
            await loadPatients()
        }
    }

    // MARK: - Sort Menu

    private func buildSortMenu() -> UIMenu {
        let byName = UIAction(
            title: "Name",
            image: UIImage(systemName: "textformat.abc"),
            state: currentSort == .name ? .on : .off
        ) { [weak self] _ in
            self?.applySort(.name)
        }

        let byCondition = UIAction(
            title: "Condition",
            image: UIImage(systemName: "stethoscope"),
            state: currentSort == .condition ? .on : .off
        ) { [weak self] _ in
            self?.applySort(.condition)
        }

        let orderTitle = isAscending ? "Sort: Ascending" : "Sort: Descending"
        let orderImage = UIImage(systemName: isAscending ? "arrow.up" : "arrow.down")
        let toggleOrder = UIAction(title: orderTitle, image: orderImage) { [weak self] _ in
            guard let self = self else { return }
            self.isAscending.toggle()
            self.applySort(self.currentSort)
        }

        let sortGroup = UIMenu(options: .displayInline, children: [byName, byCondition])
        let orderGroup = UIMenu(options: .displayInline, children: [toggleOrder])

        return UIMenu(title: "Sort Options", image: nil, children: [sortGroup, orderGroup])
    }

    private func applySort(_ option: PatientSortOption) {
        currentSort = option

        switch option {
        case .name:
            filteredPatients.sort { 
                let name0 = $0.name.lowercased()
                let name1 = $1.name.lowercased()
                return isAscending ? (name0 < name1) : (name0 > name1)
            }
        case .condition:
            filteredPatients.sort {
                let cond0 = ($0.condition ?? "").lowercased()
                let cond1 = ($1.condition ?? "").lowercased()
                return isAscending ? (cond0 < cond1) : (cond0 > cond1)
            }
        }

        // Refresh the menu checkmark
        sortBarButton.menu = buildSortMenu()
        collectionView.reloadSections(IndexSet(integer: 1))
    }
    
    func loadPatients() async {

        guard let doctorId = doctor?.docID else { return }

        do {
            let fetched = try await viewModel?.fetchPatients(for: doctorId)
            patients = fetched ?? []
            filteredPatients = patients
            let patientIDs = patients.map { $0.patientID }

            let counts = try await AccessSupabase.shared
                .fetchCompletedSessionCounts(patientIDs: patientIDs)

            sessionCountByPatient = counts

            // Apply current sort after data load
            applySort(currentSort)

        } catch {
            print("Failed to fetch patients: \(error)")
            patients = []
            filteredPatients = []
        }

        collectionView.reloadSections(IndexSet(integer: 1))
    }

    func setupCollectionView() {

        collectionView.register(
            UINib(nibName: "PatientCell", bundle: nil),
            forCellWithReuseIdentifier: "PatientCell"
        )

        collectionView.register(
            UINib(nibName: "TopSecCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "TopCell"
        )
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {

        if section == 0 { return 1 }

        return filteredPatients.count
    }


    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopCell",
                for: indexPath
            ) as! TopSecCollectionViewCell

            cell.onSearchTextChanged = { [weak self] text in
                self?.filterPatients(searchText: text)
            }
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PatientCell",
            for: indexPath
        ) as! PatientCell

        let patient = filteredPatients[indexPath.row]
        let count = sessionCountByPatient[patient.patientID] ?? 0

        cell.configureCell(with: patient, sessionCount: count)
        style(cell)
        return cell
    }
        
    override func collectionView(_ collectionView: UICollectionView,
                                    didSelectItemAt indexPath: IndexPath) {

        if indexPath.section == 1 {
            let selectedPatient = filteredPatients[indexPath.row]
            let storyboard = UIStoryboard(name: "PatientDetail", bundle: nil)

            let vc = storyboard.instantiateViewController(
                withIdentifier: "PatientDetail"
            ) as! PatientDetailCollectionViewController

            vc.patient = selectedPatient

            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func filterPatients(searchText: String) {

        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if search.isEmpty {
            filteredPatients = patients
        } else {

            filteredPatients = patients.filter {
                $0.name.lowercased().contains(search.lowercased())
            }
        }

        collectionView.reloadSections(IndexSet(integer: 1))
    }

    func createLayout() -> UICollectionViewCompositionalLayout {

        UICollectionViewCompositionalLayout { sectionIndex, _ in
            return self.sectionLayout(for: sectionIndex)
        }
    }

    func sectionLayout(for section: Int) -> NSCollectionLayoutSection {

        switch section {

        case 0:
            return topSectionLayout()

        case 1:
            return patientSectionLayout()

        default:
            return patientSectionLayout()
        }
    }

    func topSectionLayout() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(60)
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        return NSCollectionLayoutSection(group: group)
    }

    func patientSectionLayout() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(120)
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        group.contentInsets = NSDirectionalEdgeInsets(
            top: 20,
            leading: 16,
            bottom: 0,
            trailing: 16
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10

        return section
    }
}


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

    var viewModel: AccessSupabase?

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = AccessSupabase()

        setupCollectionView()

        collectionView.setCollectionViewLayout(createLayout(), animated: false)

        Task {
            await loadPatients()
        }
    }

    // MARK: Load Patients

    @MainActor
    func loadPatients() async {

        guard let doctorId = UUID(uuidString: "6bf94a4d-cc66-4d87-a90d-be2500434e3d") else { return }

        let fetched = await viewModel?.fetchPatients(for: doctorId)

        patients = fetched ?? []
        filteredPatients = patients

        collectionView.reloadSections(IndexSet(integer: 1))
    }

    // MARK: Register Cells

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

    // MARK: Sections

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {

        if section == 0 { return 1 }

        return filteredPatients.count
    }

    // MARK: Cells

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
        cell.configureCell(with: patient)

        return cell
    }

    // MARK: Search

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

    // MARK: Layout

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
            heightDimension: .absolute(120)
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
            top: 10,
            leading: 16,
            bottom: 0,
            trailing: 16
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10

        return section
    }
}


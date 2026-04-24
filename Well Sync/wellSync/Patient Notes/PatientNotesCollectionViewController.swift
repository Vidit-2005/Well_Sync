//
//  PatientNotesCollectionViewController.swift
//  wellSync
//
//  Created by Rishika Mittal on 13/03/26.
//
//

import UIKit
import Foundation

private let reuseIdentifier = "Cell"

class PatientNotesCollectionViewController: UICollectionViewController {
    
    var onAdd: (() -> Void)?
    var notes: [PatientNote]?
    
    var patient: Patient? {
        didSet {
            guard patient != nil else { return }
            load()
        }
    }
    
    var patientID: UUID?
    
    // ✅ ONBOARDING
    private var onboardingSequence: FeatureOnboardingSequence?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(
            UINib(nibName: "PatientNotesCollectionReusableView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "pateintNoteHeader"
        )
        if !(notes?.isEmpty ?? false){
            collectionView.reloadSections(IndexSet(integer: 1))
        }
        self.collectionView.collectionViewLayout = createLayout()
        
        // ✅ INIT ONBOARDING
        onboardingSequence = FeatureOnboardingSequence(
            viewController: self,
            storageKey: "patient_notes"
        ) { [weak self] in
            self?.makeOnboardingSteps() ?? []
        }
        collectionView.alwaysBounceVertical = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startOnboardingIfPossible()
        focusTextView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func load() {
        guard let patientID = patient?.patientID else {
            print("Patient not set yet ❌")
            return
        }

        Task {
            do {
                let fetchedNotes = try await AccessSupabase.shared.fetchPatientNotes(patientID: patientID)
                
                await MainActor.run {
                    self.notes = fetchedNotes
                    self.collectionView.reloadData()
                    
                    // ✅ TRIGGER AFTER LOAD
                    DispatchQueue.main.async {
                        self.startOnboardingIfPossible()
                    }
                }
                
            } catch {
                print("Error:", error)
            }
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return (notes?.isEmpty ?? true) ? 1 : 2
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return notes?.count ?? 0
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "currentNotes",
                for: indexPath
            )
            
            if let button = cell.viewWithTag(2) as? UIButton {
                button.addTarget(self, action: #selector(addNoteTapped), for: .touchUpInside)
                button.superview?.bringSubviewToFront(button)
                button.isUserInteractionEnabled = true
            }
            style(cell)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "patientNotesCell",
            for: indexPath
        ) as! PatientNoteCollectionViewCell
        
        cell.configure(with: notes![indexPath.row], index: (notes?.count ?? 0) - indexPath.row)
        style(cell)
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView,contextMenuConfigurationForItemAt indexPath: IndexPath,point: CGPoint) ->UIContextMenuConfiguration? {
        
        // ❌ Disable for section 0
        if indexPath.section == 0 { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) {
                [weak self] _ in
                
                guard let self = self,
                      let note = self.notes?[indexPath.row] else { return }
                
                Task {
                    do {
                        try await AccessSupabase.shared.deletePatientNote(noteID: note.noteId)
                        
                        await MainActor.run {
                            self.notes?.remove(at: indexPath.row)
                            
                            if self.notes?.isEmpty ?? true {
                                self.collectionView.reloadData()
                            } else {
                                self.collectionView.performBatchUpdates {
                                    self.collectionView.deleteItems(at: [indexPath])
                                } completion: { _ in
                                    
                                    for cell in self.collectionView.visibleCells {
                                        if let indexPath = self.collectionView.indexPath(for: cell),
                                           indexPath.section == 1,
                                           let noteCell = cell as? PatientNoteCollectionViewCell {
                                            
                                            let newIndex = (self.notes?.count ?? 0) - indexPath.row
                                            
                                            UIView.transition(with: noteCell.noteNumber,duration: 0.25,options: .transitionCrossDissolve,
                                                              animations: {
                                                noteCell.noteNumber.text = "Note \(newIndex)"
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }
                        catch {
                        print("Delete error:", error)
                    }
                }
            }
            
            return UIMenu(title: "", children: [delete])
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "pateintNoteHeader",
            for: indexPath
        ) as! PatientNotesCollectionReusableView

        if indexPath.section == 0 {
            header.configure(with: "Quick note for your next session")
        } else if !(notes?.isEmpty ?? true) {
            header.configure(with: "Previous Notes")
        }

        return header
    }

    // MARK: - Layout

    func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(60)
        )

        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            return self.sectionLayout(for: sectionIndex)
        }
    }

    func sectionLayout(for section: Int) -> NSCollectionLayoutSection {
        let header = headerItem()
        
        let layout: NSCollectionLayoutSection
        
        if section == 0 {
            layout = section0Layout()
        } else {
            layout = section1Layout()
        }
        
        layout.boundarySupplementaryItems = [header]
        return layout
    }

    func section0Layout() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200)
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        group.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16)
        
        return NSCollectionLayoutSection(group: group)
    }
    func focusTextView() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            let indexPath = IndexPath(item: 0, section: 0)
            
            guard let cell = self.collectionView.cellForItem(at: indexPath),
                  let textView = cell.viewWithTag(1) as? UITextView else {
                return
            }
            
            textView.isEditable = true
            textView.becomeFirstResponder()
        }
    }

    func section1Layout() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(150)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(150)
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        group.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        
        return section
    }
    
    
    // MARK: - Add Note

    @objc func addNoteTapped() {
        guard let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)),
              let textField = cell.viewWithTag(1) as? UITextView else {
            print("cell or textField not found")
            return
        }

        guard let text = textField.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("text is empty")
            return
        }

        textField.text = ""
        textField.resignFirstResponder()

        let newNote = PatientNote(
            noteId: UUID(),
            patientId: patient?.patientID ?? UUID(),
            date: Date(),
            note: text
        )

        Task {
            do {
                try await AccessSupabase.shared.savePatientNote(newNote)
                let updatedNotes = try await AccessSupabase.shared.fetchPatientNotes(patientID: patient?.patientID ?? UUID())
                
                await MainActor.run {
                    self.notes = updatedNotes
                    self.collectionView.reloadData()
                    
                    DispatchQueue.main.async {
                        self.startOnboardingIfPossible()
                    }
                }
                
            } catch {
                print("Error saving/fetching note:", error)
            }
        }
    }

    // MARK: - ✅ ONBOARDING STEPS

    private func makeOnboardingSteps() -> [FeatureSpotlightStep] {
        collectionView.layoutIfNeeded()

        return [
            FeatureSpotlightStep(
                title: "Capture a quick note",
                message: "Write something important for your next session.",
                placement: .below,
                targetProvider: { [weak self] in
                    self?.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
                }
            ),
            FeatureSpotlightStep(
                title: "Save your note",
                message: "Tap this button to store it.",
                placement: .below,
                targetProvider: { [weak self] in
                    guard let self,
                          let cell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
                    else { return nil }
                    return cell.viewWithTag(2)
                }
            ),
            FeatureSpotlightStep(
                title: "View past notes",
                message: "All your saved notes appear here.",
                placement: .above,
                targetProvider: { [weak self] in
                    guard let self,
                          !(self.notes?.isEmpty ?? true)
                    else { return nil }
                    return self.collectionView.cellForItem(at: IndexPath(item: 0, section: 1))
                }
            )
        ]
    }

    private func startOnboardingIfPossible() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.onboardingSequence?.startIfNeeded()
        }
    }
}

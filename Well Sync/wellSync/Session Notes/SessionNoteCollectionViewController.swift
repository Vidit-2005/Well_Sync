//
//  SessionNoteCollectionViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 10/03/26.
//

import UIKit
import Foundation

class SessionNoteCollectionViewController: UICollectionViewController {

    var patient: Patient?
    var appointment: Appointment?
    var sessions: [SessionNote] = []
    var sizeOfNotes: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = generateLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
            loadSessionNotes()
    }
    func loadSessionNotes() {
        Task {
            guard let patientID = patient?.patientID else { return }

            do {
                let fetched = try await AccessSupabase.shared.fetchSessionNotes(patientID: patientID)
                await MainActor.run {
                    self.sessions = fetched
                    self.sizeOfNotes = self.sessions.count
                    self.collectionView.reloadData()
                }
            } catch {
                print("❌ fetch error:", error)
            }
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessions.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sessionCell", for: indexPath) as! SessionNoteCollectionViewCell
        cell
            .configur(
                with: sessions[indexPath.row],
                index: (sizeOfNotes ?? 0) - indexPath.row
            )
        return cell
    }

    func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(150.0))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .flexible(16)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)
        section.interGroupSpacing = 16

        return UICollectionViewCompositionalLayout(section: section)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "detailSession", sender: indexPath)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSession",
           let indexPath = sender as? IndexPath,
           let vc = segue.destination as? DetailSessionCollectionViewController {

            vc.session = sessions[indexPath.row]
            vc.title = "Session \(sessions.count - indexPath.row)"
        }

        if let navVC = segue.destination as? UINavigationController,
           let addVC = navVC.topViewController as? AddSessionCollectionViewController {
            addVC.patientID = patient?.patientID
            addVC.appointmentID = appointment?.appointmentId
            addVC.onSessionAdded = { [weak self] in
                self?.loadSessionNotes()
            }
        }
    }
    
    // MARK: - Context Menu for Deletion
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.confirmDeleteSession(at: indexPath)
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [deleteAction])
        }
    }
    
    private func confirmDeleteSession(at indexPath: IndexPath) {
        let session = sessions[indexPath.row]
        guard let sessionId = session.sessionId else { return }
        
        let alert = UIAlertController(
            title: "Delete Session Note",
            message: "Are you sure you want to delete this session note? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteSession(sessionId: sessionId, at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    private func deleteSession(sessionId: UUID, at indexPath: IndexPath) {
        Task {
            do {
                try await AccessSupabase.shared.deleteSessionNote(sessionID: sessionId)
                await MainActor.run {
                    self.sessions.remove(at: indexPath.row)
                    // If you just delete the item, the index path calculation in cellForItemAt might be off,
                    // so calling reloadData is safer to update all indices in the UI.
                    self.loadSessionNotes()
                }
            } catch {
                print("❌ Failed to delete session note: \(error)")
                await MainActor.run {
                    let errorAlert = UIAlertController(title: "Error", message: "Failed to delete the session note. Please try again.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }

}

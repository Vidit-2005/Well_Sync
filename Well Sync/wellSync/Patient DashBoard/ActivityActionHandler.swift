//
//  ActivityActionHandler.swift
//  wellSync
//
//  Created by Rishika Mittal on 11/04/26.
//

import UIKit
import PhotosUI

/// Owns ALL activity-button logic for both table and collection views.
/// Set the 4 properties, then call handle(item:) from any button tap.
class ActivityActionHandler: NSObject,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate,
                             PHPickerViewControllerDelegate {

    // MARK: - Required — set by owning VC before any tap

    weak var presentingViewController: UIViewController?
    var patient: Patient?

    // MARK: - Callbacks

    /// Called when a non-upload (timer) activity is tapped — VC performs its segue
    var onTimerTapped: ((TodayActivityItem) -> Void)?

    /// Called after a log is successfully saved — VC reloads its data
    var onSuccess: (() -> Void)?

    /// Called on upload/save failure
    var onFailure: ((Error) -> Void)?

    // MARK: - Private state

    private var selectedItem: TodayActivityItem?
    private var uploads: [UIImage] = []

    // MARK: - Main entry point

    /// Call this from ANY button tap (cell callback, IBAction, etc.)
    /// It automatically routes to upload menu or timer based on item type.
    func handle(item: TodayActivityItem) {
        if item.isUploadType {
            presentUploadMenu(for: item)
        } else {
            onTimerTapped?(item)
        }
    }

    // MARK: - Upload menu

    private func presentUploadMenu(for item: TodayActivityItem) {
        selectedItem = item
        uploads      = []

        let alert = UIAlertController(title: "Add Photo",
                                      message: nil,
                                      preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera",
                                          style: .default) { [weak self] _ in
                self?.openPicker(sourceType: .camera)
            })
        }

        alert.addAction(UIAlertAction(title: "Photo Library",
                                      style: .default) { [weak self] _ in
            self?.openPicker(sourceType: .photoLibrary)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentingViewController?.present(alert, animated: true)
    }

    // MARK: - Pickers

    private func openPicker(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .camera {
            let picker           = UIImagePickerController()
            picker.delegate      = self
            picker.sourceType    = .camera
            picker.allowsEditing = true
            presentingViewController?.present(picker, animated: true)
        } else {
            var config            = PHPickerConfiguration()
            config.selectionLimit = 5
            config.filter         = .images
            let picker            = PHPickerViewController(configuration: config)
            picker.delegate       = self
            presentingViewController?.present(picker, animated: true)
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let edited   = info[.editedImage]   as? UIImage { uploads.append(edited) }
        else if let orig = info[.originalImage] as? UIImage { uploads.append(orig) }
        picker.dismiss(animated: true) { self.saveLog() }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let total  = results.count
        var loaded = 0

        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage { self.uploads.append(image) }
                    loaded += 1
                    if loaded == total { self.saveLog() }
                }
            }
        }
    }

    // MARK: - Save to Supabase

    private func saveLog() {
        guard let item    = selectedItem,
              let patient = patient else {
            print("ActivityActionHandler: missing item or patient")
            return
        }
        guard !uploads.isEmpty else {
            print("ActivityActionHandler: no images selected")
            return
        }

        Task {
            do {
                var uploadedPaths: [String] = []
                for image in uploads {
                    let path = try await AccessSupabase.shared.uploadActivityImage(image)
                    uploadedPaths.append(path)
                }

                let formatter        = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"

                let log = ActivityLog(
                    logID:      UUID(),
                    assignedID: item.assignment.assignedID,
                    activityID: item.activity.activityID,
                    patientID:  patient.patientID,
                    date:       Date(),
                    time:       formatter.string(from: Date()),
                    duration:   nil,
                    uploadPath: uploadedPaths.joined(separator: ",")
                )

                let saved = try await AccessSupabase.shared.saveActivityLog(log)
                print("ActivityActionHandler: saved", saved.logID)

                await MainActor.run {
                    self.uploads      = []
                    self.selectedItem = nil
                    self.onSuccess?()
                }

            } catch {
                print("ActivityActionHandler error:", error)
                await MainActor.run { self.onFailure?(error) }
            }
        }
    }
}

extension ActivityActionHandler {

    // Exposed so the cell's UIMenu can pick camera vs library directly
    // without going through the action sheet again
    func openPickerDirectly(sourceType: UIImagePickerController.SourceType) {
        openPicker(sourceType: sourceType)
    }

    // Exposed so the VC can set state before calling openPickerDirectly
    var selectedItemPublic: TodayActivityItem? {
        get { selectedItem }
        set { selectedItem = newValue }
    }
}

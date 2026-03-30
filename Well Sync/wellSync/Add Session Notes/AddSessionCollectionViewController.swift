//
//  AddSessionCollectionViewController.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 25/03/26.
//

import UIKit
import AVFoundation
import UniformTypeIdentifiers

class AddSessionCollectionViewController: UICollectionViewController,TextFieldCollectionViewCellDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIDocumentPickerDelegate {
    private var images: [UIImage] = []

    private var recordingURLs: [URL] = []

    private var recordingDates: [String] = []

    private var sessionTitle: String = ""
    
    private var isUploading = false
    var onSessionAdded: (() -> Void)?

    var patientID: UUID?{
        didSet{
            print(patientID ?? "")
        }
    }
    var appointmentID: UUID?
    
    @IBOutlet weak var clipButton: UIBarButtonItem!
    @IBOutlet weak var uploadButton: UIBarButtonItem!

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(
            UINib(nibName: "textFieldCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "textCell"
        )
        collectionView.register(
            UINib(nibName: "RIViewCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "recordingCell"
        )
        collectionView.register(
            UINib(nibName: "ImageViewCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "imageCell"
        )

        collectionView.collectionViewLayout = generateLayout()
        collectionView.alwaysBounceVertical = true

        setupClipMenu()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
                        as? textFieldCollectionViewCell {
            cell.writtenNote.becomeFirstResponder()
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:  return 1
        case 1:  return recordingURLs.count
        default: return images.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "textCell", for: indexPath
            ) as! textFieldCollectionViewCell
            cell.delegate = self
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "recordingCell", for: indexPath
            ) as! RIViewCollectionViewCell

            let url       = recordingURLs[indexPath.item]
            let dateStr   = recordingDates[indexPath.item]
            cell.configure(
                fileName:   url.lastPathComponent,
                dateString: dateStr
            )
            return cell

        default:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "imageCell", for: indexPath
            ) as! ImageViewCollectionViewCell

            cell.configure(with: images[indexPath.item])
            return cell
        }
    }

    // MARK: - Compositional Layout

    func generateLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch sectionIndex {

            case 0:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension:  .fractionalWidth(1.0),
                    heightDimension: .estimated(150)
                )
                let item  = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension:  .fractionalWidth(1.0),
                        heightDimension: .estimated(150)
                    ),
                    repeatingSubitem: item,
                    count: 1
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 12, leading: 16, bottom: 8, trailing: 16
                )
                return section

            case 1:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension:  .fractionalWidth(1.0),
                    heightDimension: .absolute(100)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 4, leading: 4, bottom: 4, trailing: 4
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension:  .fractionalWidth(1.0),
                        heightDimension: .absolute(108)
                    ),
                    repeatingSubitem: item,
                    count: 1
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8, leading: 16, bottom: 16, trailing: 16
                )
                return section

            default:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension:  .fractionalWidth(0.5),
                    heightDimension: .absolute(160)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 4, leading: 4, bottom: 4, trailing: 4
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension:  .fractionalWidth(1.0),
                        heightDimension: .absolute(168)
                    ),
                    repeatingSubitem: item,
                    count: 2
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8, leading: 16, bottom: 16, trailing: 16
                )
                return section
            }
        }
    }

    private func setupClipMenu() {
        let camera = UIAction(
            title: "Camera",
            image: UIImage(systemName: "camera")
        ) { [weak self] _ in self?.openCamera() }

        let library = UIAction(
            title: "Photo Library",
            image: UIImage(systemName: "photo")
        ) { [weak self] _ in self?.openGallery() }

        let recording = UIAction(
            title: "Recording",
            image: UIImage(systemName: "mic")
        ) { [weak self] _ in self?.pickAudioFromStorage() }

        clipButton.menu           = UIMenu(title: "", children: [camera, library, recording])
        clipButton.target         = nil
        clipButton.primaryAction  = nil
        clipButton.action         = nil
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Unavailable", message: "Camera is not available on this device.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = self
        present(picker, animated: true)
    }

    private func openGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate   = self
        present(picker, animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true) {
            guard let pickedImage = info[.originalImage] as? UIImage else { return }

            self.images.append(pickedImage)

            let newIndexPath = IndexPath(item: self.images.count - 1, section: 2)

            self.collectionView.performBatchUpdates {
                self.collectionView.insertItems(at: [newIndexPath])
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func pickAudioFromStorage() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.audio],
            asCopy: true
        )
        picker.delegate              = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        recordingURLs.append(url)
        recordingDates.append(dateFormatter.string(from: Date()))

        let newIndexPath = IndexPath(item: recordingURLs.count - 1, section: 1)
        collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: [newIndexPath])
        }
    }

    private func currentTitle() -> String {
        let fallback = "Session - \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
        return sessionTitle.trimmingCharacters(in: .whitespaces).isEmpty ? fallback : sessionTitle
    }

    private func currentNoteText() -> String {
        let indexPath = IndexPath(item: 0, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath)
                          as? textFieldCollectionViewCell else { return "" }
        return cell.writtenNote.text ?? ""
    }
    
    @IBAction func upload(_ sender: UIBarButtonItem) {

        // ── Guard: patient ID is required ─────────────────────────────────────
        guard let patientID = patientID else {
            showAlert(title: "Missing Patient",
                      message: "Patient ID was not passed to this screen.")
            return
        }

        let noteText  = currentNoteText()
        let noteTitle = currentTitle()

        guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              || !images.isEmpty
              || !recordingURLs.isEmpty else {
            showAlert(title: "Nothing to save",
                      message: "Please write a note or add an image or recording.")
            return
        }

        guard !isUploading else { return }
        isUploading = true

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)

        Task {
            do {
                var imagePaths: [String] = []
                for image in images {
                    let path = try await SupabaseManager.shared.uploadImage(image)
                    imagePaths.append(path)
                    print("✅ Image uploaded → \(SupabaseManager.shared.publicURL(for: path))")
                }

                var audioPaths: [String] = []
                for url in recordingURLs {
                    let path = try await SupabaseManager.shared.uploadAudio(from: url)
                    audioPaths.append(path)
                    print("✅ Audio uploaded  → \(SupabaseManager.shared.publicURL(for: path))")
                }

                let note = SessionNote(
                    sessionId:     nil,
                    patientId:     patientID,
                    date:          Date(),
                    notes:         noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                       ? nil
                                       : noteText,
                    images:        imagePaths.isEmpty ? nil : imagePaths,
                    voice:         audioPaths.isEmpty ? nil : audioPaths,
                    title:         noteTitle,
                    appointmentId: appointmentID
                )

                let savedNote = try await AccessSupabase.shared.saveSessionNote(note)
                print("✅ SessionNote saved → ID: \(savedNote.sessionId?.uuidString ?? "unknown")")

                await MainActor.run {
                    self.isUploading = false
                    self.navigationItem.rightBarButtonItem = self.uploadButton
                    self.showAlert(
                        title: "Saved!",
                        message: "Session note saved successfully.",
                        dismissAction: {
                            self.onSessionAdded?()
                            self.dismiss(animated: true)
                        }
                    )
                }

            } catch {
                await MainActor.run {
                    self.isUploading = false
                    self.navigationItem.rightBarButtonItem = self.uploadButton
                    self.showAlert(title: "Save Failed",
                                   message: error.localizedDescription)
                }
            }
        }
    }
    

    func textFieldCell(_ cell: textFieldCollectionViewCell, didChangeHeight height: CGFloat) {
        collectionView.performBatchUpdates {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    @IBAction func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    private func showAlert(title: String,
                           message: String,
                           dismissAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            dismissAction?()
        })
        present(alert, animated: true)
    }
}

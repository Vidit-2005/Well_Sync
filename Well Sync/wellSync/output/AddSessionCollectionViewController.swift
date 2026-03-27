//
//  AddSessionCollectionViewController.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 25/03/26.
//
//  ── Section map ────────────────────────────────────────────────────────────
//  Section 0 │ Text field          │ textFieldCollectionViewCell  (1 item)
//  Section 1 │ Audio recordings   │ RIViewCollectionViewCell     (recording.count items)
//  Section 2 │ Picked images      │ ImageViewCollectionViewCell  (image.count items)
//  ───────────────────────────────────────────────────────────────────────────

import UIKit
import AVFoundation
import UniformTypeIdentifiers

class AddSessionCollectionViewController: UICollectionViewController,
                                          TextFieldCollectionViewCellDelegate,
                                          UIImagePickerControllerDelegate,
                                          UINavigationControllerDelegate,
                                          UIDocumentPickerDelegate {

    // MARK: - Data model
    /// Each picked image stored in-memory for immediate preview.
    private var images: [UIImage] = []

    /// Local file URLs of picked audio files.
    private var recordingURLs: [URL] = []

    /// Human-readable timestamps parallel to `recordingURLs`.
    private var recordingDates: [String] = []

    // MARK: - Upload state
    private var isUploading = false

    // MARK: - Bar buttons
    @IBOutlet weak var clipButton: UIBarButtonItem!
    @IBOutlet weak var uploadButton: UIBarButtonItem!      // the existing "upload" bar button

    // MARK: - Date formatter (reused)
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // ── Cell registration ──────────────────────────────────────────────
        // "textCell"      → Section 0: text field
        collectionView.register(
            UINib(nibName: "textFieldCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "textCell"
        )
        // "recordingCell" → Section 1: audio files  (RIViewCollectionViewCell)
        collectionView.register(
            UINib(nibName: "RIViewCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "recordingCell"
        )
        // "imageCell"     → Section 2: picked images (ImageViewCollectionViewCell)
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
        // Auto-focus the text field when the sheet opens
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
                        as? textFieldCollectionViewCell {
            cell.writtenNote.becomeFirstResponder()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:  return 1                   // always one text field
        case 1:  return recordingURLs.count // audio rows
        default: return images.count        // image thumbnails
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {

        // ── Section 0: Text field ─────────────────────────────────────────
        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "textCell", for: indexPath
            ) as! textFieldCollectionViewCell
            cell.delegate = self
            return cell

        // ── Section 1: Audio recordings ───────────────────────────────────
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

        // ── Section 2: Images ─────────────────────────────────────────────
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

            // ── Section 0: Self-sizing text field ─────────────────────────
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

            // ── Section 1: Full-width audio rows ──────────────────────────
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
                section.orthogonalScrollingBehavior = .groupPaging
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8, leading: 16, bottom: 16, trailing: 16
                )
                return section

            // ── Section 2: 2-column image grid ───────────────────────────
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
                section.orthogonalScrollingBehavior = .groupPaging
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8, leading: 16, bottom: 16, trailing: 16
                )
                return section
            }
        }
    }

    // MARK: - Clip menu setup

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

    // MARK: - Camera / Gallery

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

    // ── UIImagePickerControllerDelegate ──────────────────────────────────────

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true) {
            // Step 1: Extract the picked UIImage
            guard let pickedImage = info[.originalImage] as? UIImage else { return }

            // Step 2: Append to data source
            self.images.append(pickedImage)

            // Step 3: Calculate the new IndexPath (last item in section 2)
            let newIndexPath = IndexPath(item: self.images.count - 1, section: 2)

            // Step 4: Insert the cell with animation — no full reload needed
            self.collectionView.performBatchUpdates {
                self.collectionView.insertItems(at: [newIndexPath])
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - Audio picker

    private func pickAudioFromStorage() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.audio],
            asCopy: true          // copies to app sandbox — no security-scope needed
        )
        picker.delegate              = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    // ── UIDocumentPickerDelegate ──────────────────────────────────────────────

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Step 1: Append URL and timestamp to parallel arrays
        recordingURLs.append(url)
        recordingDates.append(dateFormatter.string(from: Date()))

        // Step 2: Insert the new row in section 1
        let newIndexPath = IndexPath(item: recordingURLs.count - 1, section: 1)
        collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: [newIndexPath])
        }
    }

    // MARK: - Upload to Supabase

    /// Called when the user taps the "Upload" bar button.
    /// Uploads all images and audio files to Supabase Storage.
    @IBAction func upload(_ sender: UIBarButtonItem) {
        guard !images.isEmpty || !recordingURLs.isEmpty else {
            showAlert(title: "Nothing to upload",
                      message: "Please pick at least one image or recording first.")
            return
        }
        guard !isUploading else { return }
        isUploading = true

        // Show a spinner while uploading
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)

        Task {
            do {
                // ── Upload images ──────────────────────────────────────────
                var imagePaths: [String] = []
                for image in images {
                    let path = try await SupabaseManager.shared.uploadImage(image)
                    imagePaths.append(path)
                    print("✅ Image uploaded: \(SupabaseManager.shared.publicURL(for: path))")
                }

                // ── Upload audio files ─────────────────────────────────────
                var audioPaths: [String] = []
                for url in recordingURLs {
                    let path = try await SupabaseManager.shared.uploadAudio(from: url)
                    audioPaths.append(path)
                    print("✅ Audio uploaded: \(SupabaseManager.shared.publicURL(for: path))")
                }

                // ── Success ────────────────────────────────────────────────
                await MainActor.run {
                    self.isUploading = false
                    self.navigationItem.rightBarButtonItem = self.uploadButton
                    self.showAlert(
                        title: "Uploaded!",
                        message: "\(imagePaths.count) image(s) and \(audioPaths.count) recording(s) saved.",
                        dismissAction: { self.dismiss(animated: true) }
                    )
                }

            } catch {
                // ── Error ──────────────────────────────────────────────────
                await MainActor.run {
                    self.isUploading = false
                    self.navigationItem.rightBarButtonItem = self.uploadButton
                    self.showAlert(
                        title: "Upload Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - TextFieldCollectionViewCellDelegate

    func textFieldCell(_ cell: textFieldCollectionViewCell, didChangeHeight height: CGFloat) {
        collectionView.performBatchUpdates {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // MARK: - Actions

    @IBAction func close(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    // MARK: - Helpers

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

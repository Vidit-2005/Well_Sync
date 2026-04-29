////
////  AddPatientTableViewController.swift
////  wellSync
////
////  Created by GEU on 31/01/26.
////

import UIKit
import Foundation
 
class AddPatientTableViewController: UITableViewController,
                                     UIImagePickerControllerDelegate,
                                     UINavigationControllerDelegate {
    var doctor: Doctor?
    
    var patient:   Patient?
    var onDismiss: (() -> Void)?
 
    @IBOutlet weak var fullName:       UITextField!
    @IBOutlet var address:             UITextField!
    @IBOutlet var contact:             UITextField!
    @IBOutlet var email:               UITextField!
    @IBOutlet var patientCase:         UITextField!
    @IBOutlet var weight:              UITextField!
    @IBOutlet var moreInfo:            UITextField!
    @IBOutlet var patientImageView:    UIImageView!
    @IBOutlet var addPhotoButton:      UIButton!
    @IBOutlet var dateOfBirth:         UIDatePicker!
    @IBOutlet var gender:              UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPhotoMenu()
        
        dateOfBirth.maximumDate = Date()
        
        setupGenderMenu()
    }
    
    func setupPhotoMenu() {
        let camera = UIAction(title: "Camera",
                              image: UIImage(systemName: "camera")) { _ in
            self.openImagePicker(sourceType: .camera)
        }
        let photoLibrary = UIAction(title: "Photo Library",
                                    image: UIImage(systemName: "photo")) { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }
        addPhotoButton.menu = UIMenu(title: "", children: [camera, photoLibrary])
        addPhotoButton.showsMenuAsPrimaryAction = true
    }

    func setupGenderMenu() {
        
        gender.setTitle("Select", for: .normal)
        let options = ["Male", "Female", "Other", "Not Specified"]
        let menuChildren = options.map { title in
            UIAction(title: title){ _ in
                self.gender.setTitle(title, for: .normal)
            }
        }
        
        gender.menu = UIMenu(children: menuChildren)
        gender.showsMenuAsPrimaryAction = true
        gender.changesSelectionAsPrimaryAction = false
    }
 
    @IBAction func addPhotoTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add Photo",
                                      message: "Choose an option",
                                      preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.openImagePicker(sourceType: .camera)
            })
        }
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        })
        present(alert, animated: true)
    }
 
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate    = self
        picker.sourceType  = sourceType
        picker.allowsEditing = true
        present(picker, animated: true)
    }
 
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let edited   = info[.editedImage]   as? UIImage { patientImageView.image = edited }
        else if let orig = info[.originalImage] as? UIImage { patientImageView.image = orig }
        dismiss(animated: true)
    }
 
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    func generateSecurePassword() -> String {
        // 1. Name (first 3 characters)
            let namePart = (fullName.text ?? "")
                .replacingOccurrences(of: " ", with: "")
                .prefix(3)
                .lowercased()

            // 2. Case (first 3 characters)
            let casePart = (patientCase.text ?? "")
                .replacingOccurrences(of: " ", with: "")
                .prefix(3)
                .lowercased()

            // 3. DOB (ddMMyyyy)
            let formatter = DateFormatter()
            formatter.dateFormat = "ddMMyyyy"
            let dobPart = formatter.string(from: dateOfBirth.date)

            return "\(namePart)\(casePart)\(dobPart)"
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {

        guard let name        = fullName.text,  !name.isEmpty,
              let emailText   = email.text,     !emailText.isEmpty,
              let contactText = contact.text,   !contactText.isEmpty,
              let addressText = address.text,   !addressText.isEmpty else {
            showAlert(title: "Missing fields",
                      message: "Please fill in Name, Email, Contact, and Address.")
            return
        }

        let resolvedDoctor = doctor ?? SessionManager.shared.currentDoctor
        guard let docID = resolvedDoctor?.docID else {
            showAlert(title: "Error",
                      message: "Could not identify the logged-in doctor. Please log out and log in again.")
            return
        }

        let dobDate = dateOfBirth.date
        let selectedGender : String?
        if gender.currentTitle == "Select" || gender.currentTitle == nil {
            selectedGender = nil
        }else{
            selectedGender = gender.currentTitle
        }
        sender.isEnabled = false
        let generatedPassword = generateSecurePassword()
 
        let loadingAlert = makeLoadingAlert(message: "Creating patient account…")
        present(loadingAlert, animated: true)
 
//        Task {
//            do {
//                var imagePath: String? = nil
//                if let image = patientImageView.image {
//                    imagePath = try await AccessSupabase.shared.uploadProfileImage(image)
//                }
//
//                var authID: UUID? = nil
//                do {
//                    authID = try await SupabaseManager.shared.signUp(
//                        email: emailText,
//                        password: generatedPassword
//                    )
//                } catch let error as NSError where error.domain == "AuthEmailConfirmation" {
//                    print("WellSync — email confirmation pending for patient: \(emailText)")
//                }
// 
//                let newPatient = Patient(
//                    patientID: UUID(),
//                    docID:     docID,
//                    authID:    authID,
//                    name:      name,
//                    email:     emailText,
//                    contact:              contactText,
//                    dob:                  dobDate,
//                    address:              addressText,
//                    condition:            patientCase.text,
//                    sessionStatus:        false,
//                    nextSessionDate:      Calendar.current.date(byAdding: .day, value: 0, to: Date())!,
//                    imageURL:             imagePath,
//                    previousSessionDate:  Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
//                    gender :              selectedGender
//                )
// 
//                try await AccessSupabase.shared.savePatient(newPatient)
//                _ = try await AccessSupabase.shared.saveCaseHistory(newPatient.patientID)
//                self.patient = newPatient
// 
//                // ── 9. Show the doctor the generated credentials to share with patient ──
//                await MainActor.run {
//                    loadingAlert.dismiss(animated: true) {
//                        self.showCredentials(email: emailText, password: generatedPassword)
//                        sender.isEnabled = true
//                    }
//                }
// 
//            } catch {
//                await MainActor.run {
//                    loadingAlert.dismiss(animated: true) {
//                        self.showAlert(title: "Error saving patient",
//                                       message: error.localizedDescription)
//                        print(error)
//                    }
//                }
//            }
//        }
        Task {
            do {
                // ── STEP A: Snapshot the doctor's Supabase session BEFORE patient signup ──
                let doctorSnapshot = await SupabaseManager.shared.getCurrentSessionTokens()

                // ── STEP B: Upload profile image (if any) ──
                var imagePath: String? = nil
                if let image = patientImageView.image {
                    imagePath = try await AccessSupabase.shared.uploadProfileImage(image)
                }

                // ── STEP C: Create Supabase Auth account for the patient ──
                // This will swap the device's auth session to the patient — that's OK,
                // we will restore the doctor's session immediately after.
                var authID: UUID? = nil
                do {
                    authID = try await SupabaseManager.shared.signUp(
                        email:    emailText,
                        password: generatedPassword
                    )
                } catch let error as NSError where error.domain == "AuthEmailConfirmation" {
                    print("WellSync — email confirmation pending for patient: \(emailText)")
                }

                // ── STEP D: Immediately restore the doctor's session ──────────────────
                // This is the key fix: undo the session swap caused by signUp above.
                if let snapshot = doctorSnapshot {
                    await SupabaseManager.shared.restoreSession(
                        accessToken:  snapshot.accessToken,
                        refreshToken: snapshot.refreshToken
                    )
                }
                // ─────────────────────────────────────────────────────────────────────

                // ── STEP E: Save patient record to database ──
                let newPatient = Patient(
                    patientID:           UUID(),
                    docID:               docID,
                    authID:              authID,
                    name:                name,
                    email:               emailText,
                    contact:             contactText,
                    dob:                 dobDate,
                    address:             addressText,
                    condition:           patientCase.text,
                    sessionStatus:       false,
                    nextSessionDate:     Calendar.current.date(byAdding: .day, value: 0, to: Date())!,
                    imageURL:            imagePath,
                    previousSessionDate: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
                    gender:              selectedGender
                )

                try await AccessSupabase.shared.savePatient(newPatient)
                _ = try await AccessSupabase.shared.saveCaseHistory(newPatient.patientID)
                self.patient = newPatient

                // ── STEP F: Send welcome e-mail with credentials ──────────────
                // Non-fatal: if the email fails we still show the doctor the
                // credentials on-screen so the patient is never left without access.
                let doctorName = resolvedDoctor?.name ?? "Your Doctor"
                var emailSent  = false
                do {
                    try await EmailService.shared.sendPatientWelcomeEmail(
                        patientEmail: emailText,
                        patientName:  name,
                        password:     generatedPassword,
                        doctorName:   doctorName
                    )
                    emailSent = true
                    print("✅ Welcome email sent to \(emailText)")
                } catch {
                    print("⚠️ Welcome email failed (non-fatal): \(error.localizedDescription)")
                }

                // ── STEP G: Show credentials to doctor ────────────────────────
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        self.showCredentials(email: emailText,
                                            password: generatedPassword,
                                            emailSent: emailSent)
                        sender.isEnabled = true
                    }
                }

            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        self.showAlert(title: "Error saving patient",
                                       message: error.localizedDescription)
                        print(error)
                        sender.isEnabled = true
                    }
                }
            }
        }
    }

    private func showCredentials(email: String, password: String, emailSent: Bool) {
        let emailNote = emailSent
            ? "📨 A welcome email with the credentials has been sent to the patient."
            : "⚠️ Email delivery failed — please share the credentials below manually."

        let alert = UIAlertController(
            title: "Patient Account Created ✅",
            message: """
            \(emailNote)
            
            The patient can log in and change their password from Settings.
            """,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            self.onDismiss?()
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
 
    // ─────────────────────────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────────────────────────
 
    private func makeLoadingAlert(message: String) -> UIAlertController {
        let alert     = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor),
            indicator.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -20)
        ])
        return alert
    }
 
    private func showAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

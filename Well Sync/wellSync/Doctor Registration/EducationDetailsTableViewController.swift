//
//  EducationDetailsTableViewController.swift
//  wellSync
//
//  Created by GEU on 11/02/26.
//

import UIKit
import UniformTypeIdentifiers

class EducationDetailsTableViewController: BaseInsetGroupedTableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    
    @IBOutlet weak var educationImageView: UIImageView!
    @IBOutlet weak var educationCertificateLabel: UILabel!
    @IBOutlet weak var educationAttachment: UIButton!
    @IBOutlet weak var registrationImageView: UIImageView!
    @IBOutlet weak var registrationDocumentLabel: UILabel!
    @IBOutlet weak var registrationAttachment: UIButton!
    @IBOutlet weak var identityImageView: UIImageView!
    @IBOutlet weak var identityDocumentLabel: UILabel!
    @IBOutlet weak var identityAttachment: UIButton!
    @IBOutlet weak var qualificationTextField: UITextField!
    @IBOutlet weak var registrationTextField: UITextField!
    @IBOutlet weak var identityTextField: UITextField!
    var selectedFileName: String?
    
    struct UploadableDocument {
        let data: Data
        let fileName: String
        let mimeType: String
    }
    
    var educationDoc: UploadableDocument?
    var registrationDoc: UploadableDocument?
    var identityDoc: UploadableDocument?
    enum AttachmentType {
        case education
        case registration
        case identity
    }

    var currentAttachmentType: AttachmentType?
    override func viewDidLoad() {
        super.viewDidLoad()

        educationCertificateLabel.text = "Add Certificate"
        educationCertificateLabel.textColor = .secondaryLabel
        registrationDocumentLabel.text = "Add Registration proof"
        registrationDocumentLabel.textColor = .secondaryLabel
        identityDocumentLabel.text = "Add ID Document"
        identityDocumentLabel.textColor = .secondaryLabel
        setupMenu()
        

    }
//    var doctor: Doctor!
    var username: String!
    var email: String!
    var password: String!
    var name: String!
    var dob: String!
    var address: String!
    var experience: Int!
    var docImage: UIImage?
    
    func setupMenu() {
           
        educationAttachment.menu = createMenu(for: .education)
        registrationAttachment.menu = createMenu(for: .registration)
        identityAttachment.menu = createMenu(for: .identity)
        educationAttachment.showsMenuAsPrimaryAction = true
        registrationAttachment.showsMenuAsPrimaryAction = true
        identityAttachment.showsMenuAsPrimaryAction = true

       }
    
    func createMenu(for type: AttachmentType) -> UIMenu {
        
        let camera = UIAction(title: "Camera",
                              image: UIImage(systemName: "camera")) { _ in
            self.currentAttachmentType = type
            self.openImagePicker(sourceType: .camera)
        }
        let photoLibrary = UIAction(title: "Photo Library",
                                    image: UIImage(systemName: "photo")) { _ in
            self.currentAttachmentType = type
            self.openImagePicker(sourceType: .photoLibrary)
        }
        
        let attachFile = UIAction(title: "Attach File",
                                  image: UIImage(systemName: "doc")) { _ in
            self.currentAttachmentType = type
            self.openDocumentPicker()
        }
        
        return UIMenu(title: "", children: [camera, photoLibrary, attachFile])
    }


    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
           let picker = UIImagePickerController()
           picker.delegate = self
           picker.sourceType = sourceType
           picker.allowsEditing = true
           present(picker, animated: true)
       }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize = CGSize(width: 800, height: 800)) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(origin: .zero, size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }

    func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        var selectedImage: UIImage?
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
               selectedImage = originalImage
            }
        guard let image = selectedImage else {return}
        let resized = resizeImage(image)
        guard let data = resized.jpegData(compressionQuality: 0.5) else {return}
        let doc = UploadableDocument(data: data, fileName: "\(UUID().uuidString).jpg", mimeType: "image/jpeg")
        
        switch currentAttachmentType {
            case .education:
                educationImageView.image = image
                educationDoc = doc
                educationCertificateLabel.text = "Document Added"
                educationCertificateLabel.textColor = .label
                
            case .registration:
                registrationImageView.image = image
                registrationDoc = doc
                registrationDocumentLabel.text = "Document Added"
                registrationDocumentLabel.textColor = .label
                
            case .identity:
                identityImageView.image = image
                identityDoc = doc
                identityDocumentLabel.text = "Document Added"
                identityDocumentLabel.textColor = .label
                
            default:
                break
            }
            dismiss(animated: true)
        }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss(animated: true)
        }
    
    func openDocumentPicker() {
           
           let types: [UTType] = [.pdf, .image]
           
           let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
           picker.delegate = self
           picker.allowsMultipleSelection = false
           present(picker, animated: true)
       }
       
       func documentPicker(_ controller: UIDocumentPickerViewController,
                           didPickDocumentsAt urls: [URL]) {
           
           guard let url = urls.first else { return }
           
           let shouldAccess = url.startAccessingSecurityScopedResource()
           defer {
               if shouldAccess {
                   url.stopAccessingSecurityScopedResource()
               }
           }
           
           do {
               var data = try Data(contentsOf: url)
               let isPDF = url.pathExtension.lowercased() == "pdf"
               
               if !isPDF, let image = UIImage(data: data) {
                   let resized = resizeImage(image)
                   if let compressedData = resized.jpegData(compressionQuality: 0.5) {
                       data = compressedData
                   }
               }
               
               let mimeType = isPDF ? "application/pdf" : "image/jpeg"
               let doc = UploadableDocument(data: data, fileName: url.lastPathComponent, mimeType: mimeType)
               
               switch currentAttachmentType {
               case .education:
                   educationDoc = doc
                   educationCertificateLabel.text = url.lastPathComponent
                   educationCertificateLabel.textColor = .label
                   
               case .registration:
                   registrationDoc = doc
                   registrationDocumentLabel.text = url.lastPathComponent
                   registrationDocumentLabel.textColor = .label
                   
               case .identity:
                   identityDoc = doc
                   identityDocumentLabel.text = url.lastPathComponent
                   identityDocumentLabel.textColor = .label
                   
               default:
                   break
               }
           } catch {
               print("Failed to read document data: \(error)")
           }
           controller.dismiss(animated: true)
       }
    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let qualification = qualificationTextField.text, !qualification.isEmpty,
              let registrationNumber = registrationTextField.text, !registrationNumber.isEmpty,
              let identityNumber = identityTextField.text, !identityNumber.isEmpty else {
            showAlert(message: "Please fill in all fields.")
            return
        }
        
        guard let eduDoc = educationDoc,
              let regDoc = registrationDoc,
              let idDoc = identityDoc else {
            showAlert(message: "Please upload all required documents.")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let parsedDOB: Date

        if let dobString = dob, !dobString.isEmpty,
           let date = dateFormatter.date(from: dobString) {
            parsedDOB = date
        } else {
            parsedDOB = Date()
        }
        // Show loading
        let alert = UIAlertController(title: nil, message: "Registering...", preferredStyle: .alert)
        present(alert, animated: true)
        
        Task {
            do {
                // Step 1: Create Supabase Auth account → get auth UUID
                let authID = try await SupabaseManager.shared.signUp(
                    email: email,
                    password: password
                )
                
                let docID = UUID()
                
                // Step 2: Save doctor profile FIRST (without document paths)
                // This is needed because the storage RLS policy requires the user
                // to exist in the doctors table before allowing uploads.
                var doctor = Doctor(
                    docID: docID,
                    authID: authID,
                    username: username,
                    email: email,
                    name: name,
                    dob: parsedDOB,
                    address: address,
                    experience: experience,
                    doctorImage: nil,
                    qualification: qualification,
                    registrationNumber: registrationNumber,
                    identityNumber: identityNumber,
                    educationImageData: nil,
                    registrationImageData: nil,
                    identityImageData: nil
                )
                
                try await AccessSupabase.shared.saveDoctor(doctor: doctor)
                
                // Step 3: Upload profile image
                var imagePath: String? = nil
                if let image = docImage {
                    let resized = resizeImage(image)
                    if let imageData = resized.jpegData(compressionQuality: 0.5) {
                        imagePath = try await SupabaseManager.shared.uploadDoctorRegistrationFile(
                            data: imageData,
                            fileName: "profile.jpg",
                            contentType: "image/jpeg"
                        )
                    }
                }
                
                // Step 4: Upload mandatory documents (each uses a fresh TCP connection)
                let educationPath = try await SupabaseManager.shared.uploadDoctorRegistrationFile(
                    data: eduDoc.data,
                    fileName: eduDoc.fileName,
                    contentType: eduDoc.mimeType
                )
                
                let registrationPath = try await SupabaseManager.shared.uploadDoctorRegistrationFile(
                    data: regDoc.data,
                    fileName: regDoc.fileName,
                    contentType: regDoc.mimeType
                )
                
                let identityPath = try await SupabaseManager.shared.uploadDoctorRegistrationFile(
                    data: idDoc.data,
                    fileName: idDoc.fileName,
                    contentType: idDoc.mimeType
                )
                
                // Step 5: Update doctor record with document paths
                doctor.doctorImage = imagePath
                doctor = Doctor(
                    docID: docID,
                    authID: authID,
                    username: username,
                    email: email,
                    name: name,
                    dob: parsedDOB,
                    address: address,
                    experience: experience,
                    doctorImage: imagePath,
                    qualification: qualification,
                    registrationNumber: registrationNumber,
                    identityNumber: identityNumber,
                    educationImageData: educationPath,
                    registrationImageData: registrationPath,
                    identityImageData: identityPath
                )
                
                let updatedDoctor = try await AccessSupabase.shared.updateDoctor(doctor)
                
                await MainActor.run {
                    alert.dismiss(animated: true) {
                        SessionManager.shared.currentDoctor = updatedDoctor
                        SessionManager.shared.saveSession(role: .doctor, authID: authID, doctorID: docID)

                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = scene.windows.first {

                            let storyboard = UIStoryboard(name: "DoctorFrontPage", bundle: nil)
                            let homeVC = storyboard.instantiateViewController(withIdentifier: "doctor")

                            window.rootViewController = homeVC
                            window.makeKeyAndVisible()
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    alert.dismiss(animated: true) {
                        print("Supabase Error: \(String(describing: error))")
                        self.showAlert(message: "Registration failed: \(String(describing: error))")
                    }
                    
                }
            }
        }
    }
    private func showAlert(message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
}

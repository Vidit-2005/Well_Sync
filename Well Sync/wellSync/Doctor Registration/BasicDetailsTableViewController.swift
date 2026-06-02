//
//  BasicDetailsTableViewController.swift
//  wellSync
//
//  Created by GEU on 11/02/26.
//

import UIKit

class BasicDetailsTableViewController: BaseInsetGroupedTableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var DoctorImageView: UIImageView!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var dobDatePicker: UIDatePicker!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var joiningDatePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPhotoMenu()
    }
    var username: String!
    var email: String!
    var password: String!
    
    func setupPhotoMenu() {
           
           let camera = UIAction(title: "Camera",
                                 image: UIImage(systemName: "camera")) { _ in
               self.openImagePicker(sourceType: .camera)
           }
           let photoLibrary = UIAction(title: "Photo Library",
                                       image: UIImage(systemName: "photo")) { _ in
               self.openImagePicker(sourceType: .photoLibrary)
           }
           let menu = UIMenu(title: "", children: [camera, photoLibrary])
           addPhotoButton.menu = menu
           addPhotoButton.showsMenuAsPrimaryAction = true
       }
    
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
           let picker = UIImagePickerController()
           picker.delegate = self
           picker.sourceType = sourceType
           picker.allowsEditing = true
           present(picker, animated: true)
       }
    
    func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let editedImage = info[.editedImage] as? UIImage {
                DoctorImageView.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                DoctorImageView.image = originalImage
            }

            dismiss(animated: true)
        }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss(animated: true)
        }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        // Validation is handled in shouldPerformSegue
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "basic_to_education" {
            guard let name = nameTextField.text, !name.isEmpty,
                  let address = addressTextField.text, !address.isEmpty else {
                showAlert(message: "Please fill in all fields")
                return false
            }
            
            guard let docImage = DoctorImageView.image, docImage != UIImage(named: "profile") else {
                showAlert(message: "Please upload a profile image")
                return false
            }
            
            if dobDatePicker.date >= Date() {
                showAlert(message: "Date of Birth must be in the past")
                return false
            }
            
            if joiningDatePicker.date > Date() {
                showAlert(message: "First joining date cannot be in the future")
                return false
            }
        }
        return true
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "basic_to_education"{
            if let destinationVC = segue.destination as? EducationDetailsTableViewController{
                destinationVC.username = username
                destinationVC.email = email
                destinationVC.password = password
                destinationVC.name = nameTextField.text
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                destinationVC.dob = dateFormatter.string(from: dobDatePicker.date)
                
                destinationVC.docImage = DoctorImageView.image
                destinationVC.address = addressTextField.text
                
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year], from: joiningDatePicker.date, to: Date())
                destinationVC.experience = components.year ?? 0
            }
        }
    }
}

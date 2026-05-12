//
//  PatientCollectionViewCell.swift
//  DoctorProfile
//
//  Created by Pranjal on 04/02/26.
//

import UIKit

class PatientCollectionViewCell: UICollectionViewCell {
    private var tagBlue: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.32, blue: 0.38, alpha: 1.0)
            : UIColor(red: 0.82, green: 0.90, blue: 0.92, alpha: 1.0)
        }
    }
    
    private var tagText: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.88, green: 0.94, blue: 0.97, alpha: 1.0)
            : UIColor(red: 0.43, green: 0.49, blue: 0.53, alpha: 1.0)
        }
    }
    
    
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet weak var sessionLabel: UILabel!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var conditionLabel: UILabel!
    @IBOutlet weak var lastDate: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    
    var onAction: ((doctorAction, UIView) -> Void)?
    
    private var leftAction: doctorAction?
    private var rightAction: doctorAction?
    override func awakeFromNib() {
        super.awakeFromNib()
        style(self)
        setupTag(conditionLabel)
        setupTag(sessionLabel)
        
        setupButton(leftButton)
        setupButton(rightButton)
    }
    
    private func setupTag(_ label: UILabel) {
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.backgroundColor = tagBlue
        label.textColor = tagText
        contentView.layer.cornerRadius = 20
        
        contentView.layer.masksToBounds = true
    }
    
    private func setupButton(_ button: UIButton) {
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
    }
    
//    private func configureButtons(_ patient: Patient){
//        if patient.sessionStatus == .done{
//
//        }
//    }
    
    private func configureButtons(status: Appointment.status) {
        leftButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .light)
            return outgoing
        }
        rightButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .light)
            return outgoing
        }

        rightButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        switch status {

        case .completed:
            leftButton.setTitle("Next Session", for: .normal)
            leftAction = .nextSession
            leftButton.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.05)
            leftButton.setTitleColor(.systemTeal, for: .normal)
            leftButton.layer.borderWidth = 0.50
            leftButton.layer.borderColor = UIColor.systemTeal.cgColor
            rightButton.setTitle("Session Note", for: .normal)
            rightAction = .addNote
            rightButton.backgroundColor = UIColor.systemMint.withAlphaComponent(0.05)
            rightButton.setTitleColor(.systemMint, for: .normal)
            rightButton.layer.borderWidth = 0.50
            rightButton.layer.borderColor = UIColor.systemMint.cgColor

        case .scheduled:
            leftButton.setTitle("Reschedule", for: .normal)
            leftAction = .reschedule
            leftButton.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.05)
            leftButton.setTitleColor(.systemTeal, for: .normal)
            leftButton.layer.borderWidth = 0.50
            leftButton.layer.borderColor = UIColor.systemTeal.cgColor
            rightButton.setTitle("Mark Done", for: .normal)
            rightAction = .markDone
            rightButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.05)
            rightButton.setTitleColor(.systemGreen, for: .normal)
            rightButton.isEnabled = true
            rightButton.layer.borderWidth = 0.50
            rightButton.layer.borderColor = UIColor.systemGreen.cgColor

        case .missed:
            leftButton.setTitle("Reschedule", for: .normal)
            leftAction = .reschedule
            leftButton.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.05)
            leftButton.setTitleColor(.systemTeal, for: .normal)
            leftButton.layer.borderWidth = 0.50
            leftButton.layer.borderColor = UIColor.systemTeal.cgColor
            rightButton.setTitle("Notify", for: .normal)
            rightAction = .notify
            rightButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.05)
            rightButton.setTitleColor(.systemBlue, for: .normal)
            rightButton.isEnabled = true
            rightButton.layer.borderWidth = 0.50
            rightButton.layer.borderColor = UIColor.systemBlue.cgColor
        }
    }
    
    func configureCell(with: Patient, status: Appointment.status, sessionCount: Int) {
        
        // Default image
        profileImage.image = UIImage(systemName: "person.circle")
        
        // ✅ IMAGE LOADING
        if let imageString = with.imageURL, !imageString.isEmpty {
            
            let currentTag = UUID().uuidString
            self.profileImage.accessibilityIdentifier = currentTag
            
            var finalURL: URL?
            
            // Case 1: already full URL
            if imageString.starts(with: "http") {
                finalURL = URL(string: imageString)
            }
            // Case 2: Supabase path
            else {
                do {
                    finalURL = try AccessSupabase.shared.getPublicImageURL(path: imageString)
                } catch {
                    print("Image URL error:", error)
                }
            }
            
            if let url = finalURL {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    guard let data = data,
                          let image = UIImage(data: data) else { return }
                    
                    DispatchQueue.main.async {
                        // Prevent wrong image due to reuse
                        if self.profileImage.accessibilityIdentifier == currentTag {
                            self.profileImage.image = image
                        }
                    }
                }.resume()
            }
        }
        
        // UI DATA
        nameLabel.text = with.name
        conditionLabel.text = with.condition
        if sessionCount > 1{
            sessionLabel.text = "\(sessionCount) Sessions"}
        else if sessionCount == 1{
            sessionLabel.text = "\(sessionCount) Session"}
        else{
            sessionLabel.text = "No Sessions"
        }
        
        // Time
        if let sessionDate = with.nextSessionDate {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.dateFormat = "HH:mm a"
            time.text = timeFormatter.string(from: sessionDate)
        }
        
        // Last session date
        if let date = with.previousSessionDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: date)
            lastDate.text = "Last session: \(dateString)"
        }
        configureButtons(status: status)
    }
    
    @IBAction func leftButtonTapped(_ sender: UIButton) {
        if let action = leftAction {
            onAction?(action, sender)
        }
    }

    @IBAction func rightButtonTapped(_ sender: UIButton) {
        if let action = rightAction {
            onAction?(action, sender)
        }
    }

}

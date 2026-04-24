//
//  PatientCollectionViewCell.swift
//  DoctorProfile
//
//  Created by Pranjal on 04/02/26.
//

import UIKit

enum AppointmentCellAction {
    case reschedule
    case cancel
}

class PatientCellAppointment: UICollectionViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sessionLabel: UILabel!
    @IBOutlet weak var lastDate: UILabel!
    @IBOutlet weak var rescheduleButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var onAction: ((AppointmentCellAction, UIView) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTag(conditionLabel)
        setupTag(sessionLabel)

        styleButton(rescheduleButton, color: .systemTeal, title: "Reschedule")
        styleButton(cancelButton, color: .systemOrange, title: "Cancel")

        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
    }
    private func setupTag(_ label: UILabel) {
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        contentView.layer.cornerRadius = 20
        
        contentView.layer.masksToBounds = true
    }
    private func setupButton(_ button: UIButton) {
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
    }
    
    private func styleButton(_ button: UIButton, color: UIColor, title: String) {
        
        var config = UIButton.Configuration.filled()
        
        config.title = title
        config.baseForegroundColor = color
        config.baseBackgroundColor = color.withAlphaComponent(0.15)
        
        config.cornerStyle = .capsule
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .medium)
            return outgoing
        }
        
        button.configuration = config
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImage.image = UIImage(systemName: "person.circle")
        nameLabel.text = nil
        conditionLabel.text = nil
        sessionLabel.text = nil
        lastDate.text = nil
    }
    
    func configure(name: String,
                   condition: String,
                   previousSessionDate: Date?,
                   imageName: String?) {
        
        nameLabel.text = name
        conditionLabel.text = condition
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yy"
        
        if let previousDate = previousSessionDate {
            lastDate.text = "Last session: \(formatter.string(from: previousDate))"
        } else {
            lastDate.text = "No previous session"
        }
    }
    
    @IBAction func rescheduleTapped(_ sender: UIButton) {
        onAction?(.reschedule, sender)
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        onAction?(.cancel, sender)
    }
    
}

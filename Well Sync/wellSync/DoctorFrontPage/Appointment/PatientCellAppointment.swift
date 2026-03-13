//
//  PatientCollectionViewCell.swift
//  DoctorProfile
//
//  Created by Pranjal on 04/02/26.
//
import UIKit

class PatientCellAppointment: UICollectionViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sessionLabel: UILabel!
    @IBOutlet weak var lastDate: UILabel!
    @IBOutlet weak var rescheduleButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setupTag(conditionLabel)
        setupTag(sessionLabel)

        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
    }

    private func setupTag(_ label: UILabel) {
        label.layer.cornerRadius = 11
        label.layer.masksToBounds = true
        label.textAlignment = .center
    }

    func configure(with patient: Patient) {

        nameLabel.text = patient.name
        conditionLabel.text = patient.condition

        // If you want to show previous session
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yy"

        if let previousDate = patient.previousSessionDate {
            lastDate.text = formatter.string(from: previousDate)
        } else {
            lastDate.text = "No previous session"
        }

        // Next appointment time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"

       // timeLabel.text = timeFormatter.string(from: patient.nextSessionDate)

        if let image = patient.imageURL {
            profileImage.image = UIImage(named: image)
        } else {
            profileImage.image = UIImage(systemName: "person.circle")
        }
    
    }
}

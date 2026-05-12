//
//  PatientCollectionViewCell.swift
//  DoctorProfile
//
//  Created by Pranjal on 04/02/26.
//
import UIKit

class PatientCell: UICollectionViewCell {
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
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var sessionLabel: UILabel!
    @IBOutlet weak var lastDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        style(self)
        
        setupTag(conditionLabel)
        setupTag(sessionLabel)
        
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
    }
    
    private func setupTag(_ label: UILabel) {
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.backgroundColor = tagBlue
        label.textColor = tagText
    }
    
    func configureCell(with patient: Patient, sessionCount: Int) {

        nameLabel.text = patient.name
        conditionLabel.text = patient.condition

        profileImage.image = UIImage(systemName: "person.circle.fill")

        // session
        if sessionCount > 1 {
            sessionLabel.text = "\(sessionCount) Sessions"
        } else if sessionCount == 1 {
            sessionLabel.text = "1 Session"
        } else {
            sessionLabel.text = "No Sessions"
        }

        // date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yy"

        if let date = patient.previousSessionDate {
            lastDate.text = "Last session: \(formatter.string(from: date))"
        } else {
            lastDate.text = "-"
        }

        // ✅ FETCH IMAGE FROM SUPABASE BUCKET
        if let path = patient.imageURL {
            Task {
                do {
                    let image = try await AccessSupabase.shared.downloadImage(path: path)
                    DispatchQueue.main.async {
                        self.profileImage.image = image
                    }
                } catch {
                    print("Image fetch failed:", error)
                }
            }
        }
    }
}

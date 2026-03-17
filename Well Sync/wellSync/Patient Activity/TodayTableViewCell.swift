//
//  TodayTableViewCell.swift
//  patientSide
//
//  Created by Rishika Mittal on 27/01/26.
//

import UIKit

class TodayTableViewCell: UITableViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var subtitleBottomConstraint: NSLayoutConstraint!
    
//     MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCard()
        // Border color must be set in code — storyboard can't handle dynamic colors

        selectionStyle              = .none
        backgroundColor             = .clear
        contentView.backgroundColor = .clear
    }

    private func setupCard() {
        selectionStyle              = .none
        backgroundColor             = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor    = .systemBackground
        cardView.layer.borderColor  = UIColor.systemGray4.cgColor
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth  = 0          // remove harsh border

        // Soft shadow instead of border
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.05
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 0)
        cardView.layer.shadowRadius  = 8
        cardView.layer.masksToBounds = false
    }
    

    // MARK: - Configure for Today Section
    func configure(with item: TodayActivityItem) {
        titleLabel.text     = item.activity.name
        dateLabel.text      = item.frequencyText          // "0 of 1 done today"
        subtitleLabel.text  = item.assignment.doctorNote ?? "No additional notes."
        subtitleLabel.isHidden = false
        let symbolConfig    = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        iconImageView.image = UIImage(systemName: item.activity.iconName, withConfiguration: symbolConfig)

        let done                 = item.isCompletedToday
//        checkmarkView.isHidden   = !done
        cardView.backgroundColor = done
            ? UIColor.systemGray6
            : UIColor.systemBackground
        contentView.alpha = done ? 0.7 : 1.0
    }

    // MARK: - Configure for Logs Section
    func configureAsLog(activityName: String, iconName: String, logCount: Int) {
        titleLabel.text          = activityName
        dateLabel.text           = "Total: \(logCount)"
        subtitleLabel.isHidden   = true               // hide note row in logs
        iconImageView.image      = UIImage(systemName: iconName)
//        checkmarkView.isHidden   = true
        subtitleBottomConstraint.constant = 8
        cardView.backgroundColor = .systemBackground
    }
}



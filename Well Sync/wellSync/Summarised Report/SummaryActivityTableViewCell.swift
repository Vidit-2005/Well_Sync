//
//  SummaryActivityTableViewCell.swift
//  wellSync
//
//  Created by Rishika Mittal on 07/02/26.
//

import UIKit

class SummaryActivityTableViewCell: UITableViewCell {

    @IBOutlet weak var stackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
        stackView.axis    = .vertical
        stackView.spacing = 16
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
    }

    // MARK: - Configure
    func configure(for patientID: UUID) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let activeAssignments = assignedActivities.filter {
            $0.patientID == patientID && $0.status == .active
        }

        for (index, assignment) in activeAssignments.enumerated() {
            guard let activity = activityCatalog.first(where: {
                $0.activityID == assignment.activityID
            }) else { continue }

            // Compute completion up to today only
            let today         = Date()
            let end           = min(assignment.endDate, today)
            let days          = Calendar.current.dateComponents(
                                    [.day], from: assignment.startDate, to: end
                                ).day ?? 0
            let totalExpected = max(1, (days + 1) * assignment.frequency)
            let totalCompleted = activityLogs.filter {
                $0.assignedID == assignment.assignedID
            }.count
            let ratio = min(Float(totalCompleted) / Float(totalExpected), 1.0)

            // Build row view
            let rowView = buildActivityRow(
                activity:       activity,
                totalCompleted: totalCompleted,
                totalExpected:  totalExpected,
                ratio:          ratio
            )
            stackView.addArrangedSubview(rowView)

            // Divider between rows
            if index < activeAssignments.count - 1 {
                let divider             = UIView()
                divider.backgroundColor = UIColor.separator
                divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }
    }

    // MARK: - Build Each Activity Row
    private func buildActivityRow(activity: Activity,
                                   totalCompleted: Int,
                                   totalExpected: Int,
                                   ratio: Float) -> UIView {

        // Icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconView   = UIImageView(image: UIImage(systemName: activity.iconName,
                                                    withConfiguration: iconConfig))
        iconView.tintColor    = .systemBlue
        iconView.contentMode  = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28)
        ])

        // Title
        let titleLabel       = UILabel()
        titleLabel.text      = activity.name
        titleLabel.font      = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.textColor = .label

        // Percent
        let percentLabel     = UILabel()
        percentLabel.text    = "\(Int(ratio * 100))%"
        percentLabel.font    = UIFont.preferredFont(forTextStyle: .headline)
        percentLabel.textColor = .systemBlue
        percentLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Top row: icon + title + percent
        let titleRow          = UIStackView(arrangedSubviews: [iconView, titleLabel, percentLabel])
        titleRow.axis         = .horizontal
        titleRow.spacing      = 10
        titleRow.alignment    = .center
        titleRow.distribution = .fill

        // Progress bar
        let progress               = UIProgressView(progressViewStyle: .default)
        progress.progress          = ratio
        progress.progressTintColor = .systemBlue
        progress.trackTintColor    = UIColor.systemGray5
        progress.transform         = progress.transform.scaledBy(x: 1, y: 2)
        progress.layer.cornerRadius = 3
        progress.clipsToBounds      = true

        // Sessions label
        let sessionLabel       = UILabel()
        sessionLabel.text      = "\(totalCompleted) of \(totalExpected) sessions done"
        sessionLabel.font      = UIFont.preferredFont(forTextStyle: .footnote)
        sessionLabel.textColor = .secondaryLabel

        // Full vertical stack
        let vertical     = UIStackView(arrangedSubviews: [titleRow, progress, sessionLabel])
        vertical.axis    = .vertical
        vertical.spacing = 8

        return vertical
    }
    
    // MARK: - Progress Color
}

//    override func awakeFromNib() {
//        super.awakeFromNib()
//        stackView.isLayoutMarginsRelativeArrangement = true
//        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
//        
//        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
//
//        // Initialization code
//    }
//
//    func configure(with activities: [Activity]) {
//        
//        // Clear old arranged subviews (important for reuse!)
//        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
//        
//        for activity in activities {
//            
//            let container = UIView()
//            
//            let titleLabel = UILabel()
////            titleLabel.text = activity.title
//            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
//            
//            let percentLabel = UILabel()
////            percentLabel.text = "\(Int(activity.completed * 100))%"
////            percentLabel.textColor = .red
//            percentLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
//
//            
////            let progress = UIProgressView(progressViewStyle: .default)
////            progress.progress = activity.completed
////            progress.progressTintColor = .cyan
////            progress.trackTintColor = .systemGray5
////            progress.layer.cornerRadius = 6
////            progress.clipsToBounds = true
//            
//            let progress = UIProgressView(progressViewStyle: .default)
////            progress.progress = activity.completed
//            progress.progressTintColor = .systemTeal
//            progress.trackTintColor = UIColor.systemGray5
//            
//            percentLabel.textColor = progress.progressTintColor
//
//            // Make it thicker
//            progress.transform = progress.transform.scaledBy(x: 1, y: 1.5)
//
//            // Rounded look
//            progress.layer.cornerRadius = 2
//            progress.clipsToBounds = true
//
//            
//            let topRow = UIStackView(arrangedSubviews: [titleLabel, percentLabel])
//            topRow.axis = .horizontal
//            topRow.distribution = .equalSpacing
//            
//            let vertical = UIStackView(arrangedSubviews: [topRow, progress])
//            vertical.axis = .vertical
////            vertical.spacing = 8
//            
//            vertical.spacing = 8
//            stackView.spacing = 16
////            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
////            percentLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
//            
//            container.addSubview(vertical)
//            vertical.translatesAutoresizingMaskIntoConstraints = false
//            
//            NSLayoutConstraint.activate([
//                vertical.topAnchor.constraint(equalTo: container.topAnchor),
//                vertical.leadingAnchor.constraint(equalTo: container.leadingAnchor),
//                vertical.trailingAnchor.constraint(equalTo: container.trailingAnchor),
//                vertical.bottomAnchor.constraint(equalTo: container.bottomAnchor)
//            ])
//            
//            stackView.addArrangedSubview(container)
//        }
//    }


//}

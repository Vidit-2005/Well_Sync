////
////  SummaryActivityTableViewCell.swift
////  wellSync
////
////  Created by Rishika Mittal on 07/02/26.
////
//
//import UIKit
//
//class SummaryActivityTableViewCell: UITableViewCell {
//
//    @IBOutlet weak var stackView: UIStackView!
//    var onFetched:(()->Void)?
//    var isLoading = true
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        stackView.isLayoutMarginsRelativeArrangement = true
//        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
//        stackView.axis    = .vertical
//        stackView.spacing = 16
//        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
//        showSkeleton()
//    }
//    private func showSkeleton() {
//        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
//
//        for _ in 0..<3 {
//            let skeleton = UIView()
//            skeleton.backgroundColor = UIColor.systemGray5
//            skeleton.layer.cornerRadius = 8
//            skeleton.clipsToBounds = true
//
//            skeleton.heightAnchor.constraint(equalToConstant: 60).isActive = true
//
//            // shimmer animation
//            let gradient = CAGradientLayer()
//            gradient.colors = [
//                UIColor.systemGray5.cgColor,
//                UIColor.systemGray4.cgColor,
//                UIColor.systemGray5.cgColor
//            ]
//            gradient.startPoint = CGPoint(x: 0, y: 0.5)
//            gradient.endPoint = CGPoint(x: 1, y: 0.5)
//            gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60)
//
//            skeleton.layer.addSublayer(gradient)
//
//            let animation = CABasicAnimation(keyPath: "transform.translation.x")
//            animation.fromValue = -UIScreen.main.bounds.width
//            animation.toValue = UIScreen.main.bounds.width
//            animation.duration = 1.2
//            animation.repeatCount = .infinity
//
//            gradient.add(animation, forKey: "shimmer")
//
//            stackView.addArrangedSubview(skeleton)
//        }
//    }
//
////    func configure(for patientID: UUID) async {
////        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
////
////        do {
////            // Was: assignedActivities.filter
////            let allAssignments = try await AccessSupabase.shared.fetchAssignments(for: patientID)
////            let activeAssignments = allAssignments.filter { $0.status == .active }
////            // Was: activityLogs.filter
////            let allLogs = try await AccessSupabase.shared.fetchLogs(for: patientID)
////
////            for (index, assignment) in activeAssignments.enumerated() {
////
////                // Was: activityCatalog.first(where:)
////                guard let activity = try await AccessSupabase.shared.fetchActivityByID(
////                    assignment.activityID
////                ) else { continue }
////
////                let today          = Date()
////                let end            = min(assignment.endDate, today)
////                let days           = Calendar.current.dateComponents(
////                                         [.day], from: assignment.startDate, to: end
////                                     ).day ?? 0
////                let totalExpected  = max(1, (days + 1) * assignment.frequency)
////                let totalCompleted = allLogs.filter {
////                    $0.assignedID == assignment.assignedID
////                }.count
////                let ratio = min(Float(totalCompleted) / Float(totalExpected), 1.0)
////
////                let rowView = buildActivityRow(
////                    activity:       activity,
////                    totalCompleted: totalCompleted,
////                    totalExpected:  totalExpected,
////                    ratio:          ratio
////                )
////
////                // UI updates must be on main thread
////                DispatchQueue.main.async {
////                    self.stackView.addArrangedSubview(rowView)
////                    if index < activeAssignments.count - 1 {
////                        let divider             = UIView()
////                        divider.backgroundColor = UIColor.separator
////                        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
////                        self.stackView.addArrangedSubview(divider)
////                    }
////                    self.onFetched?()
////                }
////            }
////
////        } catch {
////            print("SummaryActivityTableViewCell configure error:", error)
////        }
////    }
//
//    func configure(for patientID: UUID) async {
//
//        DispatchQueue.main.async {
//            self.showSkeleton()
//        }
//
//        do {
//            let allAssignments = try await AccessSupabase.shared.fetchAssignments(for: patientID)
//            let activeAssignments = allAssignments.filter { $0.status == .active }
//            let allLogs = try await AccessSupabase.shared.fetchLogs(for: patientID)
//
//            DispatchQueue.main.async {
//                self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
//            }
//
//            for (index, assignment) in activeAssignments.enumerated() {
//
//                guard let activity = try await AccessSupabase.shared.fetchActivityByID(
//                    assignment.activityID
//                ) else { continue }
//
//                let today = Date()
//                let end = min(assignment.endDate, today)
//                let days = Calendar.current.dateComponents([.day], from: assignment.startDate, to: end).day ?? 0
//
//                let totalExpected = max(1, (days + 1) * assignment.frequency)
//                let totalCompleted = allLogs.filter {
//                    $0.assignedID == assignment.assignedID
//                }.count
//
//                let ratio = min(Float(totalCompleted) / Float(totalExpected), 1.0)
//
//                let rowView = buildActivityRow(
//                    activity: activity,
//                    totalCompleted: totalCompleted,
//                    totalExpected: totalExpected,
//                    ratio: ratio
//                )
//
//                DispatchQueue.main.async {
//                    self.stackView.addArrangedSubview(rowView)
//
//                    if index < activeAssignments.count - 1 {
//                        let divider = UIView()
//                        divider.backgroundColor = UIColor.separator
//                        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
//                        self.stackView.addArrangedSubview(divider)
//                    }
//                }
//            }
//
//            DispatchQueue.main.async {
//                self.onFetched?()
//            }
//
//        } catch {
//            print("error:", error)
//        }
//    }
//    private func buildActivityRow(activity: Activity,
//                                   totalCompleted: Int,
//                                   totalExpected: Int,
//                                   ratio: Float) -> UIView {
//
//        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
//        let iconView   = UIImageView(image: UIImage(systemName: activity.iconName,
//                                                    withConfiguration: iconConfig))
//        iconView.tintColor    = .systemBlue
//        iconView.contentMode  = .scaleAspectFit
//        iconView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            iconView.widthAnchor.constraint(equalToConstant: 28),
//            iconView.heightAnchor.constraint(equalToConstant: 28)
//        ])
//
//        let titleLabel       = UILabel()
//        titleLabel.text      = activity.name
//        titleLabel.font      = UIFont.preferredFont(forTextStyle: .body)
//        titleLabel.textColor = .label
//
//        let percentLabel     = UILabel()
//        percentLabel.text    = "\(Int(ratio * 100))%"
//        percentLabel.font    = UIFont.preferredFont(forTextStyle: .headline)
//        percentLabel.textColor = .systemBlue
//        percentLabel.setContentHuggingPriority(.required, for: .horizontal)
//
//        let titleRow          = UIStackView(arrangedSubviews: [iconView, titleLabel, percentLabel])
//        titleRow.axis         = .horizontal
//        titleRow.spacing      = 10
//        titleRow.alignment    = .center
//        titleRow.distribution = .fill
//
//        let progress               = UIProgressView(progressViewStyle: .default)
//        progress.progress          = ratio
//        progress.progressTintColor = .systemBlue
//        progress.trackTintColor    = UIColor.systemGray5
//        progress.transform         = progress.transform.scaledBy(x: 1, y: 2)
//        progress.layer.cornerRadius = 3
//        progress.clipsToBounds      = true
//
//        let sessionLabel       = UILabel()
//        sessionLabel.text      = "\(totalCompleted) of \(totalExpected) sessions done"
//        sessionLabel.font      = UIFont.preferredFont(forTextStyle: .footnote)
//        sessionLabel.textColor = .secondaryLabel
//        let vertical     = UIStackView(arrangedSubviews: [titleRow, progress, sessionLabel])
//        vertical.axis    = .vertical
//        vertical.spacing = 8
//
//        return vertical
//    }
//    
//}

import UIKit

class SummaryActivityTableViewCell: UITableViewCell {

    @IBOutlet weak var stackView: UIStackView!
    var onFetched: (() -> Void)?

    private let skeletonCount = 1

    override func awakeFromNib() {
        super.awakeFromNib()

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
        stackView.axis = .vertical
        stackView.spacing = 16

        showSkeleton()
    }

    // MARK: - Skeleton
    private func showSkeleton() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for _ in 0..<skeletonCount {
            let skeleton = UIView()
            skeleton.backgroundColor = UIColor.systemGray5
            skeleton.layer.cornerRadius = 8
            skeleton.clipsToBounds = true
            skeleton.heightAnchor.constraint(equalToConstant: 60).isActive = true

            skeleton.alpha = 0
            stackView.addArrangedSubview(skeleton)

            UIView.animate(withDuration: 0.2) {
                skeleton.alpha = 1
            }
        }
    }
    private func createEmptyView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 60).isActive = true

        let label = UILabel()
        label.text = "No activity data"
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .center

        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }
    

//    // MARK: - Configure
//    func configure(for patientID: UUID) async {
//
//        DispatchQueue.main.async {
//            self.showSkeleton()
//        }
//
//        do {
//            let allAssignments = try await AccessSupabase.shared.fetchAssignments(for: patientID)
//            let activeAssignments = allAssignments.filter { $0.status == .active }
//            let allLogs = try await AccessSupabase.shared.fetchLogs(for: patientID)
//
//            for (index, assignment) in activeAssignments.enumerated() {
//
//                guard let activity = try await AccessSupabase.shared.fetchActivityByID(
//                    assignment.activityID
//                ) else { continue }
//
//                let today = Date()
//                let end = min(assignment.endDate, today)
//
//                let days = Calendar.current.dateComponents([.day],
//                                                           from: assignment.startDate,
//                                                           to: end).day ?? 0
//
//                let totalExpected = max(1, (days + 1) * assignment.frequency)
//
//                let totalCompleted = allLogs.filter {
//                    $0.assignedID == assignment.assignedID
//                }.count
//
//                let ratio = min(Float(totalCompleted) / Float(totalExpected), 1.0)
//
//                let rowView = buildActivityRow(
//                    activity: activity,
//                    totalCompleted: totalCompleted,
//                    totalExpected: totalExpected,
//                    ratio: ratio
//                )
//
//                DispatchQueue.main.async {
//
//                    // 🔥 Replace skeleton OR append
//                    if index < self.stackView.arrangedSubviews.count {
//                        let skeleton = self.stackView.arrangedSubviews[index]
//
//                        UIView.transition(with: skeleton,
//                                          duration: 0.25,
//                                          options: .transitionCrossDissolve) {
//                            self.stackView.removeArrangedSubview(skeleton)
//                            skeleton.removeFromSuperview()
//                        }
//
//                        self.stackView.insertArrangedSubview(rowView, at: index)
//                    } else {
//                        self.stackView.addArrangedSubview(rowView)
//                    }
//
//                    // 🔥 Animate row
//                    rowView.alpha = 0
//                    rowView.transform = CGAffineTransform(translationX: 0, y: 10)
//
//                    UIView.animate(
//                        withDuration: 0.35,
//                        delay: Double(index) * 0.05,
//                        usingSpringWithDamping: 0.8,
//                        initialSpringVelocity: 0.5,
//                        options: [.curveEaseOut],
//                        animations: {
//                            rowView.alpha = 1
//                            rowView.transform = .identity
//                        }
//                    )
//
//                    self.onFetched?()
//                }
//            }
//
//            // 🔥 Remove leftover skeletons
//            DispatchQueue.main.async {
//                let extra = self.stackView.arrangedSubviews.dropFirst(activeAssignments.count)
//                for view in extra {
//                    self.stackView.removeArrangedSubview(view)
//                    view.removeFromSuperview()
//                }
//                self.onFetched?()
//            }
//
//        } catch {
//            print("❌ error:", error)
//        }
//    }
    func configure(for patientID: UUID) async {

        DispatchQueue.main.async {
            self.showSkeleton()
        }

        do {
            let allAssignments = try await AccessSupabase.shared.fetchAssignments(for: patientID)
            let activeAssignments = allAssignments.filter { $0.status == .active }
            let allLogs = try await AccessSupabase.shared.fetchLogs(for: patientID)

            // 🔥 EMPTY STATE
            if activeAssignments.isEmpty {
                DispatchQueue.main.async {
                    self.stackView.arrangedSubviews.forEach {
                        $0.layer.removeAllAnimations()
                        self.stackView.removeArrangedSubview($0)
                        $0.removeFromSuperview()
                    }

                    let emptyView = self.createEmptyView()
                    self.stackView.addArrangedSubview(emptyView)

                    self.onFetched?()
                }
                return
            }

            for (index, assignment) in activeAssignments.enumerated() {

                guard let activity = try await AccessSupabase.shared.fetchActivityByID(
                    assignment.activityID
                ) else { continue }

                let today = Date()
                let end = min(assignment.endDate, today)

                let days = Calendar.current.dateComponents([.day],
                                                           from: assignment.startDate,
                                                           to: end).day ?? 0

                let totalExpected = max(1, (days + 1) * assignment.frequency)

                let totalCompleted = allLogs.filter {
                    $0.assignedID == assignment.assignedID
                }.count

                let ratio = min(Float(totalCompleted) / Float(totalExpected), 1.0)

                let rowView = buildActivityRow(
                    activity: activity,
                    totalCompleted: totalCompleted,
                    totalExpected: totalExpected,
                    ratio: ratio
                )

                DispatchQueue.main.async {

                    // 🔥 Replace skeleton OR append
                    if index < self.stackView.arrangedSubviews.count {
                        let skeleton = self.stackView.arrangedSubviews[index]

                        skeleton.layer.removeAllAnimations()

                        UIView.transition(with: skeleton,
                                          duration: 0.25,
                                          options: .transitionCrossDissolve) {
                            self.stackView.removeArrangedSubview(skeleton)
                            skeleton.removeFromSuperview()
                        }

                        self.stackView.insertArrangedSubview(rowView, at: index)
                    } else {
                        self.stackView.addArrangedSubview(rowView)
                    }

                    // 🔥 Animate row
                    rowView.alpha = 0
                    rowView.transform = CGAffineTransform(translationX: 0, y: 10)

                    UIView.animate(
                        withDuration: 0.35,
                        delay: Double(index) * 0.05,
                        usingSpringWithDamping: 0.8,
                        initialSpringVelocity: 0.5,
                        options: [.curveEaseOut],
                        animations: {
                            rowView.alpha = 1
                            rowView.transform = .identity
                        }
                    )

                    self.onFetched?()
                }
            }

            // 🔥 Remove leftover skeletons
            DispatchQueue.main.async {
                let extra = self.stackView.arrangedSubviews.dropFirst(activeAssignments.count)
                for view in extra {
                    view.layer.removeAllAnimations()
                    self.stackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }
                self.onFetched?()
            }

        } catch {
            print("❌ error:", error)
        }
    }
    // MARK: - UI Builder
    private func buildActivityRow(activity: Activity,
                                 totalCompleted: Int,
                                 totalExpected: Int,
                                 ratio: Float) -> UIView {

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: activity.iconName,
                                                  withConfiguration: iconConfig))
        iconView.tintColor = .systemBlue
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 28).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = activity.name

        let percentLabel = UILabel()
        percentLabel.text = "\(Int(ratio * 100))%"
        percentLabel.textColor = .systemBlue

        let titleRow = UIStackView(arrangedSubviews: [iconView, titleLabel, percentLabel])
        titleRow.axis = .horizontal
        titleRow.spacing = 10

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = ratio

        let sessionLabel = UILabel()
        sessionLabel.text = "\(totalCompleted) of \(totalExpected) sessions done"
        sessionLabel.font = .systemFont(ofSize: 12)
        sessionLabel.textColor = .secondaryLabel

        let vertical = UIStackView(arrangedSubviews: [titleRow, progress, sessionLabel])
        vertical.axis = .vertical
        vertical.spacing = 8

        return vertical
    }
}

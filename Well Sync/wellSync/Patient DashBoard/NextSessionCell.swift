//
//  NextSessionCell.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 24/03/26.
//


import UIKit

class NextSessionCell: UICollectionViewCell {

    // MARK: – Outlets (connect from storyboard)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var doctorLabel: UILabel!

    // Countdown pill — created in code, no storyboard needed
    private let countdownPill = PillLabel()

    // MARK: – Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
        addCountdownPill()
    }

    // MARK: – Appearance

    private func setupAppearance() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        layer.masksToBounds = true

        titleLabel.text          = "Next Session"

        doctorLabel.textColor    = .label

        dateTimeLabel.textColor  = .secondaryLabel
    }

    private func addCountdownPill() {
        countdownPill.font               = .systemFont(ofSize: 12, weight: .semibold)
        countdownPill.textColor          = UIColor(red: 0.94, green: 0.47, blue: 0, alpha: 1)
        countdownPill.backgroundColor    = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1)
        countdownPill.layer.cornerRadius = 12
        countdownPill.layer.masksToBounds = true
        countdownPill.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(countdownPill)

        // Pin pill to top-right of cell
        NSLayoutConstraint.activate([
            countdownPill.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            countdownPill.centerYAnchor.constraint(equalTo: doctorLabel.centerYAnchor)
        ])
    }

    func configure(doctorName: String, sessionDate: Date) {
        doctorLabel.text = doctorName

        // Date · Time
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        let datePart = df.string(from: sessionDate)
        df.dateFormat = "h:mm a"
        let timePart = df.string(from: sessionDate)
        dateTimeLabel.text = "\(datePart)  ·  \(timePart)"

        // Countdown pill
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: sessionDate)
        ).day ?? 0

        switch days {
        case 0:
            countdownPill.text         = "  Today  "
            countdownPill.textColor    = .systemRed
            countdownPill.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        case 1:
            countdownPill.text = "  Tomorrow  "
            resetPillToOrange()
        default:
            countdownPill.text = "  In \(days) days  "
            resetPillToOrange()
        }
    }

    private func resetPillToOrange() {
        countdownPill.textColor       = UIColor(red: 0.94, green: 0.47, blue: 0, alpha: 1)
        countdownPill.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1)
    }
}

// MARK: – PillLabel
// Adds internal padding to a UILabel without a wrapper view
final class PillLabel: UILabel {
    private let h: CGFloat = 10
    private let v: CGFloat = 5

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: h, dy: v))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + h * 2, height: s.height + v * 2)
    }
}

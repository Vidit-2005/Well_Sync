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
    @IBOutlet weak var addPhotoButton: UIButton!
    var onTimerTapped: (() -> Void)?
    
    var onPhotoSourceSelected: ((UIImagePickerController.SourceType) -> Void)?
    /// Storyboard default for the subtitle-to-card-bottom constraint
    private var defaultSubtitleBottomConstant: CGFloat = -8

    override func awakeFromNib() {
        super.awakeFromNib()
        styleTableCell(self)
        // Capture the storyboard value so we can restore it on reuse
        defaultSubtitleBottomConstant = subtitleBottomConstraint.constant
        setupCard()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset every property that differs between the three cell styles
        subtitleLabel.isHidden   = false
        addPhotoButton.isHidden  = false
        addPhotoButton.isEnabled = true
        addPhotoButton.menu      = nil
        addPhotoButton.showsMenuAsPrimaryAction = false
        addPhotoButton.removeTarget(nil, action: nil, for: .touchUpInside)
        contentView.alpha        = 1.0
        cardView.backgroundColor = UIColor.tertiarySystemBackground
        subtitleBottomConstraint.constant = defaultSubtitleBottomConstant
        onTimerTapped            = nil
        onPhotoSourceSelected    = nil
    }

    private func setupCard() {
        selectionStyle              = .none
//        cardView.layer.borderColor  = UIColor.systemGray4.cgColor
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth  = 0
//        cardView.layer.shadowColor   = UIColor.black.cgColor
//        cardView.layer.shadowOpacity = 0.05
//        cardView.layer.shadowOffset  = CGSize(width: 0, height: 0)
//        cardView.layer.shadowRadius  = 8
        cardView.layer.masksToBounds = false
        iconImageView.contentMode = .scaleAspectFit
    }
    
    private func icon(for systemName: String) -> UIImage? {
        // `lungs.fill` has more internal padding than icons like `paintpalette`,
        // so we give it a slightly larger symbol size for visual parity.
        let pointSize: CGFloat = systemName == "lungs.fill" ? 36 : 30
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        return UIImage(systemName: systemName, withConfiguration: config)
    }
    
    func setupPhotoMenu() {

        let camera = UIAction(title: "Camera",
                            image: UIImage(systemName: "camera")) { [weak self] _ in
            self?.onPhotoSourceSelected?(.camera)
        }

        let photoLibrary = UIAction(title: "Photo Library",
                            image: UIImage(systemName: "photo")) { [weak self] _ in
            self?.onPhotoSourceSelected?(.photoLibrary)
        }

        let menu = UIMenu(title: "", children: [camera, photoLibrary])
        addPhotoButton.menu = menu
        addPhotoButton.showsMenuAsPrimaryAction = true
    }
    
    func configureAsLog(activityName: String, iconName: String, logCount: Int) {
        titleLabel.text          = activityName
        dateLabel.text           = "Total: \(logCount)"
        subtitleLabel.isHidden   = true
        iconImageView.image      = icon(for: iconName)
        subtitleBottomConstraint.constant = 8
        addPhotoButton.isHidden  = true
    }
    func configure(with item: TodayActivityItem) {
        titleLabel.text        = item.activity.name
        dateLabel.text         = item.frequencyText
        subtitleLabel.text     = item.assignment.doctorNote ?? "No additional notes."
        subtitleLabel.isHidden = false
        iconImageView.image    = icon(for: item.activity.iconName)

        // Restore full bottom padding (subtitle is visible)
        subtitleBottomConstraint.constant = defaultSubtitleBottomConstant

        let done                 = item.isCompletedToday
        cardView.backgroundColor = done ? UIColor.systemGray5 : UIColor.tertiarySystemBackground
        contentView.alpha        = done ? 0.8 : 1.0

        addPhotoButton.isHidden = false
        setupPhotoMenu()
    }

    func configureAsTimer(with item: TodayActivityItem) {
        titleLabel.text        = item.activity.name
        dateLabel.text         = item.frequencyText
        subtitleLabel.text     = item.assignment.doctorNote ?? "No additional notes."
        subtitleLabel.isHidden = false
        iconImageView.image    = icon(for: item.activity.iconName)

        // Restore full bottom padding (subtitle is visible)
        subtitleBottomConstraint.constant = defaultSubtitleBottomConstant

        let done                 = item.isCompletedToday
        cardView.backgroundColor = done ? UIColor.systemGray5 : UIColor.tertiarySystemBackground
        contentView.alpha        = done ? 0.8 : 1.0

        // ← RESET hidden state before setting up (fixes reuse bug)
        addPhotoButton.isHidden = false
        setupTimerButton()
    }

    func setupTimerButton() {
        addPhotoButton.menu                    = nil
        addPhotoButton.showsMenuAsPrimaryAction = false

        // ← REMOVE old targets first (fixes multiple-fire bug on reuse)
        addPhotoButton.removeTarget(nil, action: nil, for: .touchUpInside)
        addPhotoButton.addTarget(self, action: #selector(timerTapped), for: .touchUpInside)
    }
    @objc private func timerTapped() {
        onTimerTapped?()
    }
    
}


//
//  EmptyStateCardView.swift
//  wellSync
//
//  Created by Pranjal on 04/02/26.
//

import UIKit

final class EmptyStateCardView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconView = UIImageView()
    private let cardView = UIView()
    
    private var cardBackgroundColor: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.tertiarySystemBackground
            : UIColor.white
        }
    }
    
    private var cardBorderColor: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.clear
            : UIColor.systemGray5
        }
    }
    
    private var cardBorderWidth: CGFloat {
        traitCollection.userInterfaceStyle == .dark ? 0 : 1
    }

    init(title: String, subtitle: String, iconSystemName: String = "tray") {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI(title: title, subtitle: subtitle, iconSystemName: iconSystemName)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupUI(title: String, subtitle: String, iconSystemName: String) {
        backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = cardBackgroundColor
        cardView.layer.cornerRadius = 20
        cardView.layer.borderWidth = cardBorderWidth
        cardView.layer.borderColor = cardBorderColor.cgColor
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.10
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: iconSystemName)
        iconView.tintColor = .systemGray2
        iconView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 170),

            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 22),
            iconView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 34),
            iconView.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cardView.backgroundColor = cardBackgroundColor
        cardView.layer.borderWidth = cardBorderWidth
        cardView.layer.borderColor = cardBorderColor.cgColor
    }
}

//
//  TimelineCollectionViewCell.swift
//  wellSync
//
//  Created by GEU on 09/03/26.
//

import UIKit

class TimelineCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    private let dotView    = UIView()
        private let pulseRing  = UIView()
        private let topLine    = UIView()
        private let bottomLine = UIView()

        private var isFirstItem = false
        private var isLastItem  = false

        // MARK: - Constants
        private let dotCenterX: CGFloat = 24
        private let dotDiameter: CGFloat = 14
        private let pulseDiameter: CGFloat = 28
        private let lineWidth: CGFloat = 2
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTimelineViews()
        styleContainerView()
    }
    
    private func setupTimelineViews() {
           // Lines
           [topLine, bottomLine].forEach {
               $0.backgroundColor = UIColor.systemGray4
               contentView.insertSubview($0, at: 0)
           }

           // Pulse ring (behind dot)
           pulseRing.backgroundColor = UIColor.systemMint.withAlphaComponent(0.25)
           pulseRing.layer.cornerRadius = pulseDiameter / 2
           pulseRing.alpha = 0
           contentView.addSubview(pulseRing)

           // Dot (on top)
           dotView.layer.cornerRadius = dotDiameter / 2
           dotView.backgroundColor = UIColor.systemGray3
           contentView.addSubview(dotView)
       }

       private func styleContainerView() {
           containerView.layer.cornerRadius = 16
//           containerView.layer.masksToBounds = false
           containerView.layer.shadowColor  = UIColor.systemGray.cgColor
           containerView.layer.shadowOpacity = 0.05
           containerView.layer.shadowRadius  = 4
           containerView.layer.shadowOffset  = CGSize(width: 0, height: 2)
           containerView.backgroundColor = UIColor.tertiarySystemBackground
       }
    
    override func layoutSubviews() {
            super.layoutSubviews()

            // Align dot vertically with dateLabel's centre
            let dotCenterY = dateLabel.frame.midY

            dotView.frame = CGRect(
                x: dotCenterX - dotDiameter / 2,
                y: dotCenterY - dotDiameter / 2,
                width: dotDiameter,
                height: dotDiameter
            )
            dotView.layer.cornerRadius = dotDiameter / 2

            pulseRing.frame = CGRect(
                x: dotCenterX - pulseDiameter / 2,
                y: dotCenterY - pulseDiameter / 2,
                width: pulseDiameter,
                height: pulseDiameter
            )

            // Top line: cell top → dot top
            let dotTop    = dotCenterY - dotDiameter / 2
            let dotBottom = dotCenterY + dotDiameter / 2

            topLine.frame = CGRect(
                x: dotCenterX - lineWidth / 2,
                y: 0,
                width: lineWidth,
                height: dotTop
            )

            // Bottom line: dot bottom → cell bottom
            bottomLine.frame = CGRect(
                x: dotCenterX - lineWidth / 2,
                y: dotBottom,
                width: lineWidth,
                height: bounds.height - dotBottom
            )

            topLine.isHidden    = isFirstItem
            bottomLine.isHidden = isLastItem
        }
    
    func configureCell(timeline: Timeline, isFirst: Bool = false, isLast: Bool = false) {
            isFirstItem = isFirst
            isLastItem  = isLast

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            dateLabel.text      = formatter.string(from: timeline.date)
            titleLabel.text     = timeline.title
            descriptionLabel.text = timeline.description

            let isToday = Calendar.current.isDateInToday(timeline.date)
            applyDotStyle(isToday: isToday)

            setNeedsLayout()
            layoutIfNeeded()
        }

        // MARK: - Dot Styling
        private func applyDotStyle(isToday: Bool) {
            stopPulse()

            if isToday {
                dotView.backgroundColor = .systemMint
                pulseRing.alpha = 1
                startPulse()
            } else {
                dotView.backgroundColor = .systemGray3
                pulseRing.alpha = 0
            }
        }

        // MARK: - Pulse Animation
        private func startPulse() {
            pulseRing.layer.removeAllAnimations()

            // Scale pulse outward
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.6
            scale.toValue   = 1.4
            scale.duration  = 1.1
            scale.autoreverses = true
            scale.repeatCount  = .infinity
            scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            // Fade out as it expands
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.9
            fade.toValue   = 0.0
            fade.duration  = 1.1
            fade.autoreverses = true
            fade.repeatCount  = .infinity
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            pulseRing.layer.add(scale, forKey: "pulseScale")
            pulseRing.layer.add(fade,  forKey: "pulseFade")
        }

        private func stopPulse() {
            pulseRing.layer.removeAllAnimations()
        }

        // MARK: - Reuse
        override func prepareForReuse() {
            super.prepareForReuse()
            stopPulse()
            pulseRing.alpha = 0
            dotView.backgroundColor = .systemGray3
        }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
            setNeedsLayout()
            layoutIfNeeded()

            let size = contentView.systemLayoutSizeFitting(
                CGSize(width: layoutAttributes.size.width, height: UIView.layoutFittingCompressedSize.height)
            )

            layoutAttributes.frame.size.height = ceil(size.height)
            return layoutAttributes
        }
    }



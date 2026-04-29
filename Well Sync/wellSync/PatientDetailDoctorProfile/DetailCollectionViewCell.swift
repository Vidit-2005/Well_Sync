//
//  DetailCollectionViewCell.swift
//  wellSync
//
//  Created by Rishika Mittal on 06/02/26.
//

import UIKit

class DetailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    let separator = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.layer.masksToBounds = true
        
        
        separator.backgroundColor = .gray
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.4)
        ])
    }
    
    
    
    let icons: [UIImage?] = [
        UIImage(systemName: "long.text.page.and.pencil"),
        UIImage(systemName: "chart.xyaxis.line"),
        UIImage(systemName: "target"),
        UIImage(systemName: "waveform.path.ecg"),
        UIImage(systemName: "heart.text.square")
    ]
    let iconsColor: [UIColor] = [.systemIndigo , .systemCyan, .systemOrange, .systemMint, .systemPurple]
    let titles: [String] = [
        "Session Notes",
        "Mood Analysis",
        "Activity Status",
        "Health Stats",
        "Patient History",
    ]
    func configure(index: Int){
        separator.isHidden = (index == 4)
        
        icon.image = icons[index]
        icon.tintColor = iconsColor[index]
        title.text = titles[index]
    }
}


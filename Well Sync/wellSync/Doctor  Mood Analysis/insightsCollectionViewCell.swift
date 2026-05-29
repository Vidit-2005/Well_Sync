//
//  insightsCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 04/02/26.
//

import UIKit

class insightsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var insight: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        style(self)
        insight.numberOfLines = 0
        insight.lineBreakMode = .byWordWrapping
    }

    func configur(with text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6 // Added line spacing for better paragraph readability
        
        let attributedString = NSAttributedString(string: text, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ])
        
        insight.attributedText = attributedString
    }
}

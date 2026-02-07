//
//  SummaryNoteTableViewCell.swift
//  wellSync
//
//  Created by Rishika Mittal on 07/02/26.
//

import UIKit

class SummaryNoteTableViewCell: UITableViewCell {

    @IBOutlet weak var noteLabel : UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

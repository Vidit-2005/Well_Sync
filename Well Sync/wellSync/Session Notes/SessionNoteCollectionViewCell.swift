//
//  SessionNoteCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 10/03/26.
//

import UIKit

class SessionNoteCollectionViewCell: UICollectionViewCell {
    @IBOutlet var sessionNumberLabel: UILabel!
    @IBOutlet var sessionSummaryLabel: UILabel!
    @IBOutlet var sessionDateLabel: UILabel!
    
    func configur(with session: SessionNote?,index: Int){
        layer.cornerRadius = 25
        sessionNumberLabel.layer.cornerRadius = 10
//        layer.masksToBounds = false
        sessionNumberLabel.text = "Session \(index)"
        sessionDateLabel.text = session?.date.formatted(date: .numeric, time: .omitted) ?? ""
        sessionSummaryLabel.text = session?.notes ?? "No Notes"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        style(self)
    }
}

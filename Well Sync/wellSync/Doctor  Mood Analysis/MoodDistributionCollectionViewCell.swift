//
//  MoodDistributionCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 23/03/26.
//

import UIKit

class MoodDistributionCollectionViewCell: UICollectionViewCell {

    var isWeekly: Bool = true
    var moodLogs: [MoodLog] = []
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func configure(moodLogs: [MoodLog]) {
        self.moodLogs = moodLogs        // triggers your existing didSet / UI refresh
    }
}

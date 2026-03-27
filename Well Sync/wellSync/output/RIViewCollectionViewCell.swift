//
//  RIViewCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 25/03/26.
//

import UIKit

class RIViewCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlets
    // titleLabel    → "Image/Recording title" (Headline label in XIB)  id: lSx-YR-YK3
    // subtitleLabel → "Upload date & time"    (Subhead label in XIB)   id: xdd-c4-WMO
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Corner radius already set via XIB userDefinedRuntimeAttribute (20)
    }

    // MARK: - Configuration
    /// Call from cellForItemAt to populate the recording row.
    /// - Parameters:
    ///   - fileName: Last path component of the audio URL (e.g. "myRecording.m4a")
    ///   - dateString: Human-readable date/time the file was picked
    func configure(fileName: String, dateString: String) {
        titleLabel?.text    = fileName
        subtitleLabel?.text = dateString
    }
}

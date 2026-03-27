//
//  ImageViewCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 27/03/26.
//

import UIKit

class ImageViewCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlet
    // Connected to the full-bleed UIImageView in ImageViewCollectionViewCell.xib
    @IBOutlet weak var photoImageView: UIImageView!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        photoImageView?.contentMode  = .scaleAspectFill
        photoImageView?.clipsToBounds = true
        // Rounded corners to match the XIB's layer.cornerRadius = 20
        layer.cornerRadius = 20
        clipsToBounds = true
    }

    // MARK: - Configuration
    /// Call this from cellForItemAt to display the picked image.
    func configure(with image: UIImage) {
        photoImageView?.image = image
    }
}
